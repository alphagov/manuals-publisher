class SectionPublishingAPILinksExporter
  def call(organisation, manual, section)
    Services.publishing_api.patch_links(
      section.uuid,
      links: {
        organisations: [organisation.content_id],
        manual: [manual.id],
      }
    )
  end
end
