class PublishingApiDraftManualExporter
  def initialize(services)
    @services = services
  end

  def call(_, manual)
    ManualPublishingAPILinksExporter.new(
      Services.publishing_api_v2.method(:patch_links),
      @services.organisation(manual.attributes.fetch(:organisation_slug)),
      manual
    ).call

    ManualPublishingAPIExporter.new(
      Services.publishing_api_v2.method(:put_content),
      @services.organisation(manual.attributes.fetch(:organisation_slug)),
      ManualRenderer.new,
      PublicationLog,
      manual
    ).call
  end
end
