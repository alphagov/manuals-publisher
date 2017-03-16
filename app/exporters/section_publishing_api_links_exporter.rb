class SectionPublishingAPILinksExporter
  def initialize(organisation, manual, document)
    @organisation = organisation
    @manual = manual
    @document = document
  end

  def call
    Services.publishing_api_v2.patch_links(content_id, exportable_attributes)
  end

private

  attr_reader :organisation, :manual, :document

  def content_id
    document.id
  end

  def exportable_attributes
    {
      links: {
        organisations: [organisation["details"]["content_id"]],
        manual: [manual.id],
      },
    }
  end
end
