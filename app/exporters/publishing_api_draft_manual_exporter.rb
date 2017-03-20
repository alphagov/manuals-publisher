class PublishingApiDraftManualExporter
  def call(_, manual)
    ManualPublishingAPILinksExporter.new(
      OrganisationFetcher.fetch(manual.attributes.fetch(:organisation_slug)),
      manual
    ).call

    ManualPublishingAPIExporter.new(
      OrganisationFetcher.fetch(manual.attributes.fetch(:organisation_slug)),
      manual
    ).call
  end
end
