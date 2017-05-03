class PublishingApiDraftSectionExporter
  def call(section, manual)
    organisation = OrganisationFetcher.fetch(manual.organisation_slug)

    SectionPublishingAPILinksExporter.new(organisation, manual, section).call
    SectionPublishingAPIExporter.new(organisation, manual, section).call
  end
end
