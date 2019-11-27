defmodule MmorpgWeb.PageController do
  use MmorpgWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
