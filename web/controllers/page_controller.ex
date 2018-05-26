defmodule Photoshare.PageController do
  use Photoshare.Web, :controller

  def index(conn, params) do
    Photoshare.PhotoController.index(conn, params)
  end
end
