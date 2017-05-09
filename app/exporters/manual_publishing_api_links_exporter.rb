class ManualPublishingAPILinksExporter
  def call(organisation, manual)
    Services.publishing_api.patch_links(
      manual.id,
      links: {
        organisations: [organisation.content_id],
        sections: manual.sections.map(&:uuid),
      }
    )
  end
end
