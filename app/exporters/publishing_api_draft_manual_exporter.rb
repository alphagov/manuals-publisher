class PublishingApiDraftManualExporter
  def call(manual)
    organisation = OrganisationsAdapter.new.find(manual.organisation_slug)

    ManualPublishingAPILinksExporter.new(organisation, manual).call
    ManualPublishingAPIExporter.new(organisation, manual).call
  end
end
