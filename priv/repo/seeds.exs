# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Consent.Repo.insert!(%Consent.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Consent.Accounts.User

now = DateTime.utc_now() |> DateTime.truncate(:second)

%User{confirmed_at: now}
|> User.registration_changeset(%{
  email: "user@example.com",
  password: "example_password"
})
|> Consent.Repo.insert!()
