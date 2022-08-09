defmodule Consent.Accounts.ConsentGroup do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  embedded_schema do
    field :slug, :string
    field :title, :string
    field :description, :string
    field :required, :boolean
    field :consent_given, :boolean
  end

  # TODO: add validations
  def changeset(consent_group, attrs) do
    consent_group
    |> cast(attrs, [:description, :title, :slug, :required, :consent_given])
    |> validate_required([:description, :title, :slug, :required])
  end

  def set_consent(group, nil) do
    %ConsentGroup{group | consent_given: true}
  end

  def set_consent(group, consented_groups) when is_list(consented_groups) do
    %ConsentGroup{
      group
      | consent_given: group.required || Enum.member?(consented_groups, group.slug)
    }
  end

  def builtin_groups() do
    [
      {"mandatory",
       %ConsentGroup{
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
       %ConsentGroup{
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
       %ConsentGroup{
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
       %ConsentGroup{
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
