defmodule Consent.Dialog.Group do
  use Ecto.Schema

  embedded_schema do
    field :title, :string, virtual: true
    field :description, :string, virtual: true
    field :show, :boolean, virtual: true
    field :required, :boolean
    field :slug, :string
    field :consent_given, :boolean
  end

  def changeset(group, attrs) do
    group
    |> Ecto.Changeset.cast(attrs, [:required, :slug, :consent_given])
    |> Ecto.Changeset.validate_required([:required, :slug, :consent_given])
  end

  def set_consent(group, nil) do
    %__MODULE__{group | show: false, consent_given: true}
  end

  def set_consent(group, consented_groups) when is_list(consented_groups) do
    consented = group.required || Enum.member?(consented_groups, group.slug)
    %__MODULE__{group | show: false, consent_given: consented}
  end

  def all_groups() do
    Enum.map(builtins(), fn {slug, _} -> slug end)
  end

  def builtins() do
    [
      {"mandatory",
       %__MODULE__{
         slug: "mandatory",
         title: "Mandatory cookies",
         required: true,
         description: """
         These cookies are necessary for the website to function and cannot
         be switched off in our systems. They are usually only set in response
         to actions made by you which amount to a request for services,
         such as setting your privacy preferences, logging in or filling
         in forms. You can set your browser to block or alert you about these
         cookies, but some parts of the site will not then work. These cookies
         do not store any personally identifiable information.
         """
       }},
      {"functional",
       %__MODULE__{
         slug: "functional",
         title: "Enhancement cookies",
         required: false,
         description: """
         These cookies enable the website to provide enhanced functionality
         and personalisation. They may be set by us or by third party providers
         whose services we have added to our pages. If you do not allow these
         cookies then some or all of these services may not function properly.
         """
       }},
      {"measurement",
       %__MODULE__{
         slug: "measurement",
         title: "Measurement cookies",
         required: false,
         description: """
         These cookies allow us to count visits and traffic sources so we can
         measure and improve the performance of our site. They help us to know
         which pages are the most and least popular and see how visitors move
         around the site. All information these cookies collect is aggregated
         and therefore anonymous. If you do not allow these cookies we will
         not know when you have visited our site, and will not be able to
         monitor its performance.
         """
       }},
      {"marketing",
       %__MODULE__{
         slug: "marketing",
         title: "Marketing cookies",
         required: false,
         description: """
         These cookies may be set through our site by our advertising partners.
         They may be used by those companies to build a profile of your
         interests and show you relevant adverts on other sites. They do not
         store directly personal information, but are based on uniquely
         identifying your browser and internet device. If you do not allow
         these cookies, you will experience less targeted advertising.
         """
       }}
    ]
  end
end
