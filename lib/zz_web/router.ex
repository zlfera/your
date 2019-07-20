defmodule ZzWeb.Router do
  use ZzWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Plugs.OnePlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ZzWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/grains", GrainController, :index
    post "/grains", GrainController, :index
    get "/index", HomeController, :index
    get "/fengya", FengYaController, :index
    get "/phone", UserController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", ZzWeb do
  #   pipe_through :api
  # end
end
