class ManualPublishingAPILinksExporter
  def initialize(export_recipient, organisation, manual)
    @export_recipient = export_recipient
    @organisation = organisation
    @manual = manual
  end

  def call
    export_recipient.call(content_id, exportable_attributes)
  end

private

  attr_reader :export_recipient, :organisation, :manual

  def content_id
    manual.id
  end

  def exportable_attributes
    {
      links: {
        organisations: [organisation["details"]["content_id"]],
        sections: manual.documents.map(&:id),
      },
    }
  end
end
