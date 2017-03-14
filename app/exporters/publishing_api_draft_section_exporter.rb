class PublishingApiDraftSectionExporter
  def initialize(services)
    @services = services
  end

  def call(section, manual)
    SectionPublishingAPILinksExporter.new(
      @services.publishing_api_v2.method(:patch_links),
      @services.organisation(manual.attributes.fetch(:organisation_slug)),
      manual,
      section
    ).call

    SectionPublishingAPIExporter.new(
      @services.organisation(manual.attributes.fetch(:organisation_slug)),
      manual,
      section
    ).call
  end
end
