class PublishingApiDraftManualExporter
  def call(manual)
    organisation = OrganisationFetcher.fetch(manual.organisation_slug)

    ManualPublishingAPILinksExporter.new(organisation, manual).call
    ManualPublishingAPIExporter.new(organisation, manual).call
  end
end
