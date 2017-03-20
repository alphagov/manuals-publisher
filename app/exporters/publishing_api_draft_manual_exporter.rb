class PublishingApiDraftManualExporter
  def call(manual)
    ManualPublishingAPILinksExporter.new(
      OrganisationFetcher.instance.call(manual.attributes.fetch(:organisation_slug)),
      manual
    ).call

    ManualPublishingAPIExporter.new(
      OrganisationFetcher.instance.call(manual.attributes.fetch(:organisation_slug)),
      manual
    ).call
  end
end
