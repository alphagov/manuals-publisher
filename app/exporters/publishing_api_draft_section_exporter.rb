class PublishingApiDraftSectionExporter
  def initialize(services)
    @services = services
  end

  def call(section, manual)
    SectionPublishingAPILinksExporter.new(
      Services.publishing_api_v2.method(:patch_links),
      OrganisationFetcher.instance.call(manual.attributes.fetch(:organisation_slug)),
      manual,
      section
    ).call

    SectionPublishingAPIExporter.new(
      OrganisationFetcher.instance.call(manual.attributes.fetch(:organisation_slug)),
      manual,
      section
    ).call
  end
end
