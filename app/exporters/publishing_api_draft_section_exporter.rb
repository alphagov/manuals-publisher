class PublishingApiDraftSectionExporter
  def call(section, manual)
    SectionPublishingAPILinksExporter.new(
      OrganisationFetcher.fetch(manual.attributes.fetch(:organisation_slug)),
      manual,
      section
    ).call

    SectionPublishingAPIExporter.new(
      OrganisationFetcher.fetch(manual.attributes.fetch(:organisation_slug)),
      manual,
      section
    ).call
  end
end
