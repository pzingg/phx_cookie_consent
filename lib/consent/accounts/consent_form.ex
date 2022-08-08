defmodule Consent.Accounts.ConsentForm do
  use Ecto.Schema
  import Ecto.Changeset

  alias Consent.Accounts.ConsentGroup

  embedded_schema do
    field :terms_version, :string
    field :terms_agreed, :boolean
    embeds_many :groups, ConsentGroup
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:terms_version, :terms_agreed])
    |> cast_embed(:groups)
    |> validate_required([:terms_version, :terms_agreed])
  end
end
