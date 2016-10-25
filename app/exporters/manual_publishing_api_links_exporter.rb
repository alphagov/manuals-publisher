class ManualPublishingAPILinksExporter

  def initialize(export_recipent, organisation, manual)
    @export_recipent = export_recipent
    @organisation = organisation
    @manual = manual
  end

  def call
    export_recipent.call(content_id, exportable_attributes)
  end

private

  attr_reader :export_recipent, :organisation, :manual

  def content_id
    manual.id
  end

  def exportable_attributes
    {
      links: {
        organisations: [organisation.details.content_id],
        sections: manual.documents.map(&:id),
      },
    }
  end
end
