defmodule Consent.Dialog.Header do
  use Ecto.Schema

  embedded_schema do
    field :title, :string
    field :description, :string
    field :show, :boolean
  end

  def builtin() do
    %__MODULE__{
      title: "This site uses cookies",
      show: true,
      description: """
      We use cookies on this site so we can provide you with personalised content,
      ads and to analyze our website's traffic.
      Check the boxes below to agree to our terms and conditions and
      to allow or restrict the cookies being used.
      """
    }
  end
end
