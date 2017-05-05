class SectionPublishingAPILinksExporter
  def initialize(organisation, manual, section)
    @organisation = organisation
    @manual = manual
    @section = section
  end

  def call
    Services.publishing_api.patch_links(content_id, exportable_attributes)
  end

private

  attr_reader :organisation, :manual, :section

  def content_id
    section.uuid
  end

  def exportable_attributes
    {
      links: {
        organisations: [organisation.content_id],
        manual: [manual.id],
      },
    }
  end
end
