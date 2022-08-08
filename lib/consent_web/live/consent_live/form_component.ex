defmodule ConsentWeb.ConsentLive.FormComponent do
  use ConsentWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :action, :new)}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket}
  end
end
