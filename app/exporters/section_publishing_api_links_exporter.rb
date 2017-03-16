class SectionPublishingAPILinksExporter
  def initialize(organisation, manual, document)
    @export_recipient = Services.publishing_api_v2.method(:patch_links)
    @organisation = organisation
    @manual = manual
    @document = document
  end

  def call
    export_recipient.call(content_id, exportable_attributes)
  end

private

  attr_reader :export_recipient, :organisation, :manual, :document

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
