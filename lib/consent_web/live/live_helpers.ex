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
  Alpine-JS only cookie consent modal component. Required assigns:

  * `:form_action`
  * `:terms_version`
  * `:groups_with_index`
  """
  def consent_modal(assigns) do
    assigns =
      assigns
      |> assign(:csrf_token, Phoenix.HTML.Tag.csrf_token_value(assigns.form_action))
      |> assign_new(:id, fn -> "consent-modal" end)
      |> assign_new(:layout_id, fn -> "layout" end)
      |> assign_new(:form_id, fn -> "consent-form" end)
      |> assign_new(:as, fn -> "consent_params" end)
      |> assign_new(:icon, fn -> "ICON" end)
      |> assign_new(:title, fn -> "Manage Cookies" end)
      |> assign_new(:confirm, fn -> "Save" end)
      |> assign_new(:cancel, fn -> "Cancel" end)
      |> assign_new(:show_event, fn -> "consent-modal-show" end)
      |> assign_new(:hide_event, fn -> "consent-modal-hide" end)
      |> assign_new(:return_to, fn -> "/" end)

    on_show_hide = [
      {:"@#{assigns.show_event}.window", "showModal = true"},
      {:"@#{assigns.hide_event}.window", "showModal = false"}
    ]

    assigns =
      assigns
      |> assign(:on_show_hide, on_show_hide)

    ~H"""
    <div id={@id}
      x-data="{ showModal: false, showGroup: '' }"
      x-cloak x-show="showModal"
      {@on_show_hide}
      @keydown.escape.window="showModal = false"
      @click.outside="showModal = false">
      <div id={@layout_id} class="fixed inset-0 z-10 overflow-y-auto fade-in">
        <!-- had phx-hook="FocusWrap" on this next element -->
        <div id={"#{@layout_id}-focus-wrap"} data-content={"##{@layout_id}-container"}>
          <span id={"#{@layout_id}-focus-wrap-start"} tabindex="0" aria-hidden="true"></span>
          <div class="flex items-end justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0" aria-labelledby={"#{@layout_id}-title"} aria-describedby={"#{@layout_id}-description"} role="dialog" aria-modal="true" tabindex="0">
            <div class="fixed inset-0 transition-opacity bg-gray-500 bg-opacity-75" aria-hidden="true"></div>
            <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">​</span>
            <!-- had phx-window-keydown on this next element -->
            <div id={"#{@layout_id}-container"} class="sticky inline-block px-4 pt-5 pb-4 overflow-hidden text-left align-bottom transform bg-white rounded-lg shadow-xl fade-in-scale sm:my-8 sm:align-middle sm:max-w-xl sm:w-full sm:p-6">
              <!-- a id="modal-return-to" class="hidden" href="/"></a -->
              <div class="sm:flex sm:items-start">
                <div class="flex items-center justify-center flex-shrink-0 w-8 h-8 mx-auto bg-purple-100 rounded-full sm:mx-0">
                  <!-- Heroicon name: outline/plus -->
                  <%= @icon %>
                </div>
                <div class="w-full mt-3 mr-12 text-center sm:mt-0 sm:ml-4 sm:text-left">
                  <h3 class="text-lg font-medium leading-6 text-gray-900" id={"#{@layout_id}-title"}>
                    <%= @title %>
                  </h3>
                  <div class="mt-2">
                    <p id={"#{@layout_id}-content"} class="text-sm text-gray-500">
                      <div id={"#{@form_id}-container"}>
                        <form action={@form_action} method="post" id={@form_id}>
                          <input name="_csrf_token" type="hidden" value={@csrf_token}>

                          <div class="pt-2 pb-2 border-t border-gray-200">
                            <h3 class="text-lg font-medium leading-6 text-gray-900">This site uses cookies</h3>
                            <div class="pb-2 mt-4 text-sm">
                              We use cookies on this site so we can provide you with personalised content,
                              ads and to analyze our website's traffic.
                              Check the boxes below to agree to our terms and conditions and
                              to allow or restrict the cookies being used.
                            </div>
                          </div>

                          <div class="pt-2 pb-2 border-t border-gray-200">
                            <div class="sm:flex sm:items-center sm:justify-between">
                              <h3 class="text-lg font-medium leading-6 text-gray-900">Terms and conditions</h3>
                              <div class="mt-3 sm:mt-0 sm:ml-4">
                                <input name={"#{@as}[terms_version]"} type="hidden" id={"#{@form_id}_terms_version"} value="1.1.0">
                                <label class="block mb-1 text-gray-700">
                                  <span class="mr-2 text-red-600 ">Required</span>
                                  <input name={"#{@as}[terms_agreed]"} type="hidden" value="false">
                                  <input name={"#{@as}[terms_agreed]"} type="checkbox" checked required id={"#{@form_id}_terms_agreed"} value="true">
                                </label>
                              </div>
                            </div>
                            <div class="mt-4 text-sm">
                              Please read the site's Terms and Conditions, version <%= @terms_version %>.
                              By continuing to use this website, you consent to those terms.
                            </div>
                          </div>

                          <%= for {cg, i} <- @groups_with_index do %>
                          <div class="pt-2 pb-2 border-t border-gray-200">
                            <div class="sm:flex sm:items-center sm:justify-between">
                              <h3 @click={"showGroup = showGroup == '#{cg.slug}' ? '' : '#{cg.slug}'"} class="px-6 py-2 text-lg font-medium leading-6 text-gray-900 border border-blue-300 rounded"><%= cg.title %></h3>
                              <div class="mt-3 sm:mt-0 sm:ml-4">
                                <input name={"#{@as}[groups][#{i}][slug]"} type="hidden" id={"#{@form_id}_#{cg.slug}_slug"} value={cg.slug}>
                                <label class="block mb-1">
                                  <%= if cg.required do %>
                                  <span class="mr-2 text-red-600">Required</span>
                                  <input name={"#{@as}    </div>
                                  [groups][#{i}][consent_given]"} type="hidden" value="false">
                                  <input name={"#{@as}[groups][#{i}][consent_given]"} type="checkbox" checked required id={"#{@form_id}_#{cg.slug}_consent_given"} value="true">
                                  <% else %>
                                  <span class="mr-2">Allow?</span>
                                  <input name={"#{@as}[groups][#{i}][consent_given]"} type="hidden" value="false">
                                  <input name={"#{@as}[groups][#{i}][consent_given]"} type="checkbox" checked={cg.consent_given} id={"#{@form_id}_#{cg.slug}_consent_given"} value="true">
                                  <% end %>
                                </label>
                              </div>
                            </div>
                            <div x-show={"showGroup == '#{cg.slug}'"} id={"#{@form_id}_#{cg.slug}_description"} class="mt-4 text-sm">
                              <%= cg.description %>
                            </div>
                          </div>
                          <% end %>

                        </form>
                      </div>
                    </p>
                  </div>
                </div>
              </div>
              <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
                <button type="submit" form={@form_id} id={"#{@layout_id}-confirm"} class="inline-flex justify-center w-full px-4 py-2 text-base font-medium text-white bg-red-600 border border-transparent rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm">
                  <%= @confirm %>
                </button>
                <button id={"#{@layout_id}-cancel"} @click={"showModal = false; window.location.href = '#{@return_to}'"} class="inline-flex justify-center w-full px-4 py-2 mt-3 text-base font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm">
                  <%= @cancel %>
                </button>
              </div>
            </div>
          </div>
          <span id={"#{@layout_id}-focus-wrap-end"} tabindex="0" aria-hidden="true"></span>
        </div>
      </div>
    </div>
    """
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
