class ManualPublishingAPILinksExporter
  def initialize(organisation, manual)
    @organisation = organisation
    @manual = manual
  end

  def call
    Services.publishing_api.patch_links(
      manual.id,
      links: {
        organisations: [organisation.content_id],
        sections: manual.sections.map(&:uuid),
      }
    )
  end

private

  attr_reader :organisation, :manual
end
