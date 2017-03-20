class PublishingApiDraftSectionExporter
  def call(section, manual)
    SectionPublishingAPILinksExporter.new(
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
