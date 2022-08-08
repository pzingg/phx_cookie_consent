defmodule Consent.Accounts.Consent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Consent.Accounts.{ConsentGroup, User}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @timestamps_opts [type: :utc_datetime]

  schema "consents" do
    field :terms, :string
    field :groups, {:array, :string}, default: []
    field :consented_at, :utc_datetime
    field :expires_at, :utc_datetime
    belongs_to :user, User, type: Ecto.UUID

    timestamps()
  end

  # TODO: add validations
  def changeset(consent, attrs) do
    consent
    |> cast(attrs, [:terms, :groups, :consented_at, :expires_at])
  end
end
