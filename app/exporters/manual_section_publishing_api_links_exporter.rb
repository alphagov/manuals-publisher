class ManualSectionPublishingAPILinksExporter

  def initialize(export_recipent, organisation, manual, document)
    @export_recipent = export_recipent
    @organisation = organisation
    @manual = manual
    @document = document
  end

  def call
    export_recipent.call(content_id, exportable_attributes)
  end

private

  attr_reader :export_recipent, :organisation, :manual, :document

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
