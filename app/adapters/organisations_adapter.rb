require "services"

class OrganisationsAdapter
  def initialize
    @cache = {}
  end

  def find(slug)
    @cache.fetch(slug) do
      response = Services.organisations.organisation(slug)
      organisation = Organisation.new(
        title: response["title"],
        web_url: response["web_url"],
        abbreviation: response["details"]["abbreviation"],
        content_id: response["details"]["content_id"],
      )
      @cache[slug] = organisation
    end
  end
end
