defmodule Photoshare.Repo.Migrations.CreatePhoto do
  use Ecto.Migration

  def change do
    create table(:photos) do
      add :filename, :string
      add :path, :string

      timestamps()
    end

  end
end
