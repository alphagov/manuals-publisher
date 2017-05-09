class SectionPublishingAPILinksExporter
  def initialize(organisation, manual, section)
    @organisation = organisation
    @manual = manual
    @section = section
  end

  def call
    Services.publishing_api.patch_links(section.uuid, exportable_attributes)
  end

private

  attr_reader :organisation, :manual, :section

  def exportable_attributes
    {
      links: {
        organisations: [organisation.content_id],
        manual: [manual.id],
      },
    }
  end
end
