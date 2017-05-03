class OrganisationsAdapter
  def find(slug)
    response = OrganisationFetcher.fetch(slug)
    Organisation.new(
      title: response["title"],
      web_url: response["web_url"],
      abbreviation: response["details"]["abbreviation"],
      content_id: response["details"]["content_id"]
    )
  end
end
