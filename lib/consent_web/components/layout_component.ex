defmodule ConsentWeb.LayoutComponent do
  use Phoenix.Component

  @doc """
  Alpine-JS only cookie consent modal component. Required assigns:

  * `:form_action`
  * `:header`
  * `:learn_more_href`
  * `:show`
  """
  def consent_summary_modal(assigns) do
    assigns =
      assigns
      |> assign(:csrf_token, Phoenix.HTML.Tag.csrf_token_value(assigns.form_action))
      |> assign_new(:show, fn -> false end)
      |> assign_new(:id, fn -> "consent-modal" end)
      |> assign_new(:layout_id, fn -> "layout" end)
      |> assign_new(:form_id, fn -> "consent-form" end)
      |> assign_new(:as, fn -> "consent_params" end)
      |> assign_new(:icon, fn -> "ICON" end)
      |> assign_new(:title, fn -> "Cookie Consent" end)
      |> assign_new(:allow_all, fn -> "Allow All" end)
      |> assign_new(:allow_none, fn -> "Allow None" end)
      |> assign_new(:learn_more, fn -> "Learn More" end)
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
      x-data={"{ showModal: #{@show}, showGroup: '' }"}
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
              <div class="w-full mt-3 text-center sm:mt-0 sm:text-left">
                <h3 class="text-lg font-medium leading-6 text-gray-900" id={"#{@layout_id}-title"}>
                  <%= @title %>
                </h3>
                <div class="mt-2">
                  <p id={"#{@layout_id}-content"} class="text-sm text-gray-500">
                    <div id={"#{@form_id}-container"}>
                      <form action={@form_action} method="post" id={@form_id}>
                        <input name="_csrf_token" type="hidden" value={@csrf_token}>

                        <div class="pt-2 pb-2 border-t border-gray-200">
                          <h3 class="text-lg font-medium leading-6 text-gray-900"><%= @header.title %></h3>
                          <div class="pb-2 mt-4 text-sm">
                            <%= @header.description %>
                          </div>
                        </div>
                      </form>
                    </div>
                  </p>
                </div>
              </div>
              <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
                <button type="submit" name={"#{@as}[allowed_cookies]"} value="all" form={@form_id} id={"#{@layout_id}-allow_all"} class="inline-flex justify-center w-full px-4 py-2 text-base font-medium text-white bg-red-600 border border-transparent rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm">
                  <%= @allow_all %>
                </button>
                <button type="submit" name={"#{@as}[allowed_cookies]"} value="none" form={@form_id} id={"#{@layout_id}-allow_none"} class="inline-flex justify-center w-full px-4 py-2 mt-3 text-base font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm">
                  <%= @allow_none %>
                </button>
                <button type="button" id={"#{@layout_id}-learn-more"} @click={"showModal = false; window.location.href = '#{@learn_more_href}'"} class="inline-flex justify-center w-full px-4 py-2 mt-3 text-base font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm">
                  <%= @learn_more %>
                </button>
                <button type="button" id={"#{@layout_id}-cancel"} @click={"showModal = false; window.location.href = '#{@return_to}'"} class="inline-flex justify-center w-full px-4 py-2 mt-3 text-base font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm">
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
  Alpine-JS only cookie consent modal component. Required assigns:

  * `:form_action`
  * `:header`
  * `:terms`
  * `:groups_with_index`
  * `:show`
  """
  def consent_details_modal(assigns) do
    assigns =
      assigns
      |> assign(:csrf_token, Phoenix.HTML.Tag.csrf_token_value(assigns.form_action))
      |> assign_new(:show, fn -> false end)
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
      x-data={"{ showModal: #{@show}, showGroup: '' }"}
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
              <div class="w-full mt-3 text-center sm:mt-0 sm:text-left">
                <h3 class="text-lg font-medium leading-6 text-gray-900" id={"#{@layout_id}-title"}>
                  <%= @title %>
                </h3>
                <div class="mt-2">
                  <p id={"#{@layout_id}-content"} class="text-sm text-gray-500">
                    <div id={"#{@form_id}-container"}>
                      <form action={@form_action} method="post" id={@form_id}>
                        <input name="_csrf_token" type="hidden" value={@csrf_token}>

                        <div class="pt-2 pb-2 border-t border-gray-200">
                          <h3 class="text-lg font-medium leading-6 text-gray-900"><%= @header.title %></h3>
                          <div class="pb-2 mt-4 text-sm">
                            <%= @header.description %>
                          </div>
                        </div>

                        <div class="pt-2 pb-2 border-t border-gray-200">
                          <div class="sm:flex sm:items-center sm:justify-between">
                            <h3 class="text-lg font-medium leading-6 text-gray-900"><%= @terms.title %></h3>
                            <div class="mt-3 sm:mt-0 sm:ml-4">
                              <input name={"#{@as}[terms][version]"} type="hidden" id={"#{@form_id}_terms_version"} value={@terms.version}>
                              <label class="block mb-1 text-gray-700">
                                <span class="mr-2 text-red-600 ">Required</span>
                                <input name={"#{@as}[terms][consent_given]"} type="hidden" value="false">
                                <input name={"#{@as}[terms][consent_given]"} type="checkbox" checked required id={"#{@form_id}_terms_consent_given"} value="true">
                              </label>
                            </div>
                          </div>
                          <div class="mt-4 text-sm">
                            <%= @terms.description %>
                          </div>
                        </div>

                        <%= for {cg, i} <- @groups_with_index do %>
                        <div class="pt-2 pb-2 border-t border-gray-200">
                          <div class="sm:flex sm:items-center sm:justify-between">
                            <div class="flex-initial w-96">
                              <h3 @click={"showGroup = showGroup == '#{cg.slug}' ? '' : '#{cg.slug}'"} class="py-1 pl-2 pr-6 text-lg font-medium leading-6 text-gray-900 border border-blue-300 rounded"><%= cg.title %></h3>
                            </div>
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
              <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
                <button type="submit" form={@form_id} id={"#{@layout_id}-confirm"} class="inline-flex justify-center w-full px-4 py-2 text-base font-medium text-white bg-red-600 border border-transparent rounded-md shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm">
                  <%= @confirm %>
                </button>
                <button type="button" id={"#{@layout_id}-cancel"} @click={"showModal = false; window.location.href = '#{@return_to}'"} class="inline-flex justify-center w-full px-4 py-2 mt-3 text-base font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm">
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
end
