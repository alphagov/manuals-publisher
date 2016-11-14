class ManualPublicationLogFilter
  def delete_logs_and_rebuild_for_major_updates_only!(slug)
    PublicationLog.with_slug_prefix(slug).destroy_all

    document_editions_for_rebuild(slug).each do |edition|
      PublicationLog.create!(
        title: edition.title,
        slug: edition.slug,
        version_number: edition.version_number,
        change_note: edition.change_note,
        created_at: edition.exported_at || edition.updated_at,
        updated_at: edition.exported_at || edition.updated_at
      )
    end
  end

  private

  def document_editions_for_rebuild(slug)
    SpecialistDocumentEdition.with_slug_prefix(slug).where(:minor_update.nin => [true]).any_of({state: "published"}, {state: "archived"})
  end
end
