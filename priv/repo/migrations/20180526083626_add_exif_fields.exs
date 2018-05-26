defmodule Photoshare.Repo.Migrations.AddExifFields do
  use Ecto.Migration

  def up do
    alter table(:photos) do
      add :latitude, :string
      add :longitude, :string
      add :datetime, :string
      add :resized_path, :string
    end

    flush()

    Photoshare.Repo.all(Photoshare.Photo)
    |> Enum.each(fn p ->
      photo = Ecto.Changeset.cast(p, %{resized_path: p.path}, ~w(resized_path))
      case Photoshare.Repo.update photo do
        {:ok, _struct} -> nil
        {:error, cs} -> IO.inspect cs
      end
    end)
  end

  def down do
    alter table(:photos) do
      remove :latitude
      remove :longitude
      remove :datetime
      remove :resized_path
    end
  end
end
