defmodule ZzWeb.HomeController do
  use ZzWeb, :controller

  def index(conn, _params) do
    redirect(conn, external: "https://youmile.youhaovip.com")
  end
end
