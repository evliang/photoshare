defmodule Photoshare.Controllers.Helpers do
    import Phoenix.Controller

    def render_ic(%Plug.Conn{params: %{"ic-request" => "true"}} = conn, page, opts) do
        render(conn, page, [layout: {Photoshare.LayoutView, "ic.html"}] ++ opts)
    end
    
    def render_ic(conn, page, opts) do
        render(conn, page, opts)
    end
end