class SectionPublishingAPILinksExporter
  def initialize(organisation, manual, section)
    @organisation = organisation
    @manual = manual
    @section = section
  end

  def call
    Services.publishing_api.patch_links(
      section.uuid,
      links: {
        organisations: [organisation.content_id],
        manual: [manual.id],
      }
    )
  end

private

  attr_reader :organisation, :manual, :section
end
