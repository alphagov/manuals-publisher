class ManualSectionPublishingAPILinksExporter
  def initialize(export_recipient, organisation, manual, document)
    @export_recipient = export_recipient
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
