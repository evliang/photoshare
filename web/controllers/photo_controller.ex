defmodule Photoshare.PhotoController do
  use Photoshare.Web, :controller
  import Photoshare.Controllers.Helpers
  alias Mogrify
  alias Photoshare.Photo

  @sbucket_name System.get_env("SBUCKET_NAME")
  @lbucket_name System.get_env("LBUCKET_NAME")

  def index(conn, %{"page" => p}) do
    IO.puts "yo"
    page =
      Photo
      |> order_by(desc: :id)
      |> Repo.paginate(page: p)
    render_ic(conn, "imglist.html", [photos: page.entries, page: page])
  end

  def index(conn, params) do
    page =
      Photo
      |> order_by(desc: :id)
      |> Repo.paginate(params)
    render(conn, Photoshare.PhotoView, "index.html", photos: page.entries, page: page)
  end

  def new(conn, _params) do
    changeset = Photo.changeset(%Photo{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"photo" => %{"image" => photo_params}}) when is_list(photo_params) do
    success_count =
      photo_params
      |> Enum.map(&add_photo(&1))
      |> Enum.count(fn x -> Kernel.elem(x,0) == :ok end)
    conn
    |> put_flash(:info, "#{success_count} photo(s) added successfully")
    |> redirect(to: photo_path(conn, :index))
  end

  def create(conn, %{"photo" => %{"image" => photo_params}}) do
    case add_photo(photo_params) do
      {:ok, _photo} ->
        conn
        |> put_flash(:info, "Photo created successfully.")
        |> redirect(to: photo_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  defp normalize_filename(filename) do
    String.replace(filename, " ", "") |> URI.encode
  end

  #inefficient fo sho. reading in image 3x with File.read, Mogrify, identify
  defp add_photo(photo_params) do
    unique_filename = "#{UUID.uuid4(:hex)}-#{normalize_filename(photo_params.filename)}"
    {:ok, img_binary} = File.read(photo_params.path)
    IO.inspect @lbucket_name
    IO.inspect unique_filename

    aws_result1 =
      ExAws.S3.put_object(@lbucket_name, unique_filename, img_binary)
      |> IO.inspect
      |> ExAws.request
    
    exif_map = create_exif_map(photo_params.path)
    
    new_file =
      case exif_map[:orientation] do
      #https://www.daveperrett.com/articles/2012/07/28/exif-orientation-handling-is-a-ghetto/
        nil ->
          resize(1000, 600, photo_params.path)
        x when x in ["1", "2", "3", "4"] ->
          resize(1000, 600, photo_params.path)
        x when x in ["5", "6", "7", "8"] ->
          resize(600, 1000, photo_params.path)
          _ ->
          :error
      end
    
    aws_result2 =
      case new_file do
        :error ->
          {:error, "file was not resized"}
        _ ->
          {:ok, img_binary} = File.read("temp.jpg")
          IO.puts "inserting aws2"
          ExAws.S3.put_object(@sbucket_name, unique_filename, img_binary)
          |> ExAws.request
      end

    case {aws_result1, aws_result2} do
      {{:ok, _}, {:ok, _}} ->
        Photo.changeset(%Photo{},
                %{filename: unique_filename,
                path: "https://s3-us-west-2.amazonaws.com/#{@lbucket_name}/#{unique_filename}",
                resized_path: "https://s3-us-west-2.amazonaws.com/#{@sbucket_name}/#{unique_filename}"}
                |> Map.merge(exif_map))
        |> Repo.insert
      {{:ok, _}, _} ->
        aws_result2
      _ ->
        aws_result1
    end
  end

  defp resize(width, height, path) do
    "convert -auto-orient -resize #{width}x#{height}^ -gravity center -extent #{width}x#{height} #{path} temp.jpg"
    |> String.to_charlist
    |> :os.cmd
  end

  defp create_exif_map(path) do
    "identify -format '%[EXIF:*]' #{path}"
    |> String.to_charlist
    |> :os.cmd
    |> to_string
    |> extract_exif_helper
  end

  defp extract_exif_helper(str) do
    str
    |> String.split("\n")
    |> Enum.map(fn str ->
        case str do
          "exif:GPSLatitude=" <> latitude ->
            {:latitude, latitude}
          "exif:GPSLongitude=" <> longitude ->
            {:longitude, longitude}
          "exif:DateTime=" <> datetime ->
            {:datetime, datetime} #unknown timezone?
          "exif:ExifImageLength=" <> width ->
            {:width, width}
          "exif:ExifImageWidth=" <> height ->
            {:height, height}
          "exif:Orientation=" <> orientation ->
            {:orientation, orientation}
          _ -> :none
        end
      end)
    |> Enum.filter(fn x -> x != :none end)
    |> Map.new
  end

  def show(conn, %{"id" => id}) do
    photo = Repo.get!(Photo, id)
    render(conn, "show.html", photo: photo)
  end

  defp get_filename(str) do
    str
    |> String.split("/")
    |> Enum.at(-1)
  end

  def delete(conn, %{"id" => id}) do
    photo = Repo.get!(Photo, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).

    ExAws.S3.delete_object(@lbucket_name, get_filename(photo.path))
    |> ExAws.request

    ExAws.S3.delete_object(@sbucket_name, get_filename(photo.resized_path))
    |> ExAws.request

    Repo.delete!(photo)

    conn
    |> put_flash(:info, "Photo deleted successfully.")
    |> redirect(to: photo_path(conn, :index))
  end
end
