defmodule Photoshare.PageController do
  use Photoshare.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
