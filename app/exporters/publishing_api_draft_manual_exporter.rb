class PublishingApiDraftManualExporter
  def call(_, manual)
    ManualPublishingAPILinksExporter.new(
      Services.publishing_api_v2.method(:patch_links),
      OrganisationFetcher.instance.call(manual.attributes.fetch(:organisation_slug)),
      manual
    ).call

    ManualPublishingAPIExporter.new(
      OrganisationFetcher.instance.call(manual.attributes.fetch(:organisation_slug)),
      PublicationLog,
      manual
    ).call
  end
end
