defmodule ConsentWeb.CookieScriptComponent do
  use Phoenix.Component

  require Logger

  def gtag_js(assigns) do
    Logger.debug("gtag_js: #{inspect(assigns)}")

    groups = assigns[:cookie_groups] || []
    measurement_id = assigns.measurement_id
    src = "https://www.googletagmanager.com/gtag/js?id=#{measurement_id}"

    {script_attrs, src_attrs} =
      if Enum.member?(groups, "measurement") do
        {[], [async: true, src: src]}
      else
        {[type: "text/plain"], [{:"data-suppressedsrc", src}]}
      end

    assigns =
      assigns
      |> assign(:src_attrs, src_attrs)
      |> assign(:script_attrs, script_attrs)

    ~H"""
    <!-- Google tag (gtag.js) -->
    <script {@script_attrs} {@src_attrs}></script>
    <script {@script_attrs}>
      window.dataLayer = window.dataLayer || [];
      function gtag() {dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', '<%= @measurement_id %>');
    </script>
    """
  end
end
