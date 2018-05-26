defmodule Photoshare.Photo do
  use Photoshare.Web, :model

  schema "photos" do
    field :filename, :string
    field :path, :string
    field :resized_path, :string

    field :latitude, :string
    field :longitude, :string
    field :datetime, :string

    timestamps()
  end

  @all_fields [:filename, :path, :resized_path, :latitude, :longitude, :datetime]
  @required_fields [:filename, :path, :resized_path]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @all_fields)
    |> validate_required(@required_fields)
  end

  # @data_dir Path.join([__DIR__, "../../", "data/photos"])
  # def persist(%Plug.Upload{filename: filename, path: path}) do
  #   destination_path = Path.join(@data_dir, filename)
  #   File.cp(path, destination_path)
  #   %Photoshare.Photo{filename: filename, path: destination_path}
  # end
end
