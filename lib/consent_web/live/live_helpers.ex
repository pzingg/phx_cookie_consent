defmodule ConsentWeb.LiveHelpers do
  @moduledoc """
  Modal helpers from live_beats
  """
  import Phoenix.LiveView
  import Phoenix.LiveView.Helpers

  alias Phoenix.LiveView.JS

  def link(%{navigate: _to} = assigns) do
    assigns = assign_new(assigns, :class, fn -> nil end)

    ~H"""
    <a href={@navigate} data-phx-link="redirect" data-phx-link-state="push" class={@class}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  def link(%{patch: to} = assigns) do
    opts = assigns |> assigns_to_attributes() |> Keyword.put(:to, to)
    assigns = assign(assigns, :opts, opts)

    ~H"""
    <%= live_patch @opts do %><%= render_slot(@inner_block) %><% end %>
    """
  end

  def link(%{} = assigns) do
    opts = assigns |> assigns_to_attributes() |> Keyword.put(:to, assigns[:href] || "#")
    assigns = assign(assigns, :opts, opts)

    ~H"""
    <%= Phoenix.HTML.Link.link @opts do %><%= render_slot(@inner_block) %><% end %>
    """
  end

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 300,
      transition:
        {"transition ease-in duration-300", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(
      to: "##{id}",
      display: "inline-block",
      transition: {"ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      display: "inline-block",
      transition:
        {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> js_exec("##{id}-confirm", "focus", [])
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.remove_class("fade-in", to: "##{id}")
    |> JS.hide(
      to: "##{id}",
      transition: {"ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      transition:
        {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.dispatch("click", to: "##{id} [data-modal-return]")
  end

  @doc """
  Pure LV modal component (from live_beats).
  """
  def modal(assigns) do
    assigns =
      assigns
      |> assign_new(:show, fn -> false end)
      |> assign_new(:patch, fn -> nil end)
      |> assign_new(:navigate, fn -> nil end)
      |> assign_new(:on_cancel, fn -> %JS{} end)
      |> assign_new(:on_confirm, fn -> %JS{} end)
      # slots
      |> assign_new(:title, fn -> [] end)
      |> assign_new(:confirm, fn -> [] end)
      |> assign_new(:cancel, fn -> [] end)
      |> assign_rest(~w(id show patch navigate on_cancel on_confirm title confirm cancel)a)

    ~H"""
    <div id={@id} class={"fixed z-10 inset-0 overflow-y-auto #{if @show, do: "fade-in", else: "hidden"}"} {@rest}>
      <.focus_wrap id={"#{@id}-focus-wrap"} content={"##{@id}-container"}>
        <div class="flex items-end justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0" aria-labelledby={"#{@id}-title"} aria-describedby={"#{@id}-description"} role="dialog" aria-modal="true" tabindex="0">
          <div class="fixed inset-0 transition-opacity bg-gray-500 bg-opacity-75" aria-hidden="true"></div>
          <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
          <div
            id={"#{@id}-container"}
            class={"#{if @show, do: "fade-in-scale", else: "hidden"} sticky inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform sm:my-8 sm:align-middle sm:max-w-xl sm:w-full sm:p-6"}
            phx-window-keydown={hide_modal(@on_cancel, @id)} phx-key="escape"
            phx-click-away={hide_modal(@on_cancel, @id)}
          >
            <%= if @patch do %>
              <.link patch={@patch} data-modal-return class="hidden"></.link>
            <% end %>
            <%= if @navigate do %>
              <.link navigate={@navigate} data-modal-return class="hidden"></.link>
            <% end %>
            <div class="sm:flex sm:items-start">
              <div class="flex items-center justify-center flex-shrink-0 w-8 h-8 mx-auto bg-purple-100 rounded-full sm:mx-0">
                <!-- Heroicon name: outline/plus -->
                ICON
              </div>
              <div class="w-full mt-3 mr-12 text-center sm:mt-0 sm:ml-4 sm:text-left">
                <h3 class="text-lg font-medium leading-6 text-gray-900" id={"#{@id}-title"}>
                  <%= render_slot(@title) %>
                </h3>
                <div class="mt-2">
                  <p id={"#{@id}-content"} class={"text-sm text-gray-500"}>
                    <%= render_slot(@inner_block) %>
                  </p>
                </div>
              </div>
            </div>
            <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
              <%= for confirm <- @confirm do %>
                <button
                  id={"#{@id}-confirm"}
                  class="inline-flex justify-center w-full px-4 py-2 text-base font-medium text-white bg-red-600 border border-transparent rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm"
                  phx-click={@on_confirm}
                  phx-disable-with
                  {assigns_to_attributes(confirm)}
                >
                  <%= render_slot(confirm) %>
                </button>
              <% end %>
              <%= for cancel <- @cancel do %>
                <button
                  class="inline-flex justify-center w-full px-4 py-2 mt-3 text-base font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm"
                  phx-click={hide_modal(@on_cancel, @id)}
                  {assigns_to_attributes(cancel)}
                >
                  <%= render_slot(cancel) %>
                </button>
              <% end %>
            </div>
          </div>
        </div>
      </.focus_wrap>
    </div>
    """
  end

  def focus_wrap(assigns) do
    ~H"""
    <div id={@id} phx-hook="FocusWrap" data-content={@content}>
      <span id={"#{@id}-start"} tabindex="0" aria-hidden="true"></span>
      <%= render_slot(@inner_block) %>
      <span id={"#{@id}-end"} tabindex="0" aria-hidden="true"></span>
    </div>
    """
  end

  @doc """
  Calls a wired up event listener to call a function with arguments.

      window.addEventListener("js:exec", e => e.target[e.detail.call](...e.detail.args))
  """
  def js_exec(js \\ %JS{}, to, call, args) do
    JS.dispatch(js, "js:exec", to: to, detail: %{call: call, args: args})
  end

  def focus(js \\ %JS{}, parent, to) do
    JS.dispatch(js, "js:focus", to: to, detail: %{parent: parent})
  end

  def focus_closest(js \\ %JS{}, to) do
    js
    |> JS.dispatch("js:focus-closest", to: to)
    |> hide(to)
  end

  defp assign_rest(assigns, exclude) do
    assign(assigns, :rest, assigns_to_attributes(assigns, exclude))
  end
end
