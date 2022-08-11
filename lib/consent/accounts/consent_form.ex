defmodule Consent.Accounts.ConsentForm do
  use Ecto.Schema
  import Ecto.Changeset

  alias Consent.Dialog.{Group, Terms}

  embedded_schema do
    embeds_one :terms, Terms
    embeds_many :groups, Group
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [])
    |> cast_embed(:terms)
    |> cast_embed(:groups)
  end
end
