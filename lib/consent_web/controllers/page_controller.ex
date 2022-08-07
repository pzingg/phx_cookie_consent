defmodule ConsentWeb.PageController do
  use ConsentWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
