# Consent

Simple cookie consent modal dialogs built with Phoenix Components and AlpineJS.

## Cookie consent preferences

Simple preference setting schema defined in `Consent.Account.ConsentSettings`
includes the date of consent, when the consent expires, and which categories ("groups")
of cookies are consented to. It also includes a `terms` string, representing the
version of a "terms and conditions" that has been aggreed to.

The settings are stored in a persistent cookie and in the Phoenix session cookie.
When a user is logged in, the settings are attached to the user's account in the
Ecto repository.  "Cookie logic" in the `ConsentWeb.UserAuth` module manages
the state of the settings through log-ins and log-outs, updating the cookies
and the Ecto repository appropriately.

If there is no consent found or if the consent has expired,
a `:show_cookie_modal` boolean assign is set to `true`, and can be used to
present the cookie consent modal (see below).

For non-LiveViews, the `ConsentWeb.UserAuth.fetch_cookie_consent/2` function
plug places the consent settings (with the key `:cookie_consent`)
and the `:show_cookie_modal` boolean in the session and
in the connection's assigns.

For LiveViews, the `ConsentWeb.UserAuth.on_mount/4` mount function sets
assigns for the consent settings (with the key `:cookie_consent`)
and the `:show_cookie_modal` boolean in the live socket.

Updating of the consent settings is done by the routes in the non-LiveView
`ConsentController`.

## Cookie consent components

* `ConsentComponent.summary/1` - presents a summary modal dialog with
  "Accept None" and "Accept All" choices. This can be conditionally shown
  by placing the component in the `app.html.heex` and `live.html.heex` layouts.
* `ConsentComponent.details/1` - presents a detailed modal dialog with
  customizable categories ("groups") to organize cookies. Non-required groups
  can be allowed or rejected.
* `CookieScriptComponent.gtag_js/1` - an example component included in the
  `root.html.heex` layout, that shows how a non-required cookie script can be
  conditionally enabled or disabled, using
  [ideas from the iubenda Cookie Solution](https://www.iubenda.com/en/help/1229-manual-tagging-blocking-cookies).

## Build and run

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Deploy on Fly.io

Successfully deployed on [Fly.io](https://fly.io), by adding the Alpine.js module to
`assets/vendor`. The `Dockerfile`, `fly.toml`, and `rel/overlays/bin/migrate`
script created by Fly.io are included in the repository. `config/runtime.exs`
is configured to work with the Fly.io command line interface (the `platform`
variable in that script is set to `:fly`).

## Deploy on Gigalixir

Was not successful in deploying on [Gigalixir](https://gigalixir.com).
The "502 Bad Request" result may have had something to do with Gigalixir's
server rather than the application. You may try to change the `platform`
variable in `config/runtime.exs` to `:gigalixir` and see if you can get it to work.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
