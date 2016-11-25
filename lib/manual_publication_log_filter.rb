class ManualPublicationLogFilter
  def initialize(manual_record)
    @manual_record = manual_record
    @manual_slug = manual_record.slug
  end

  def delete_logs_and_rebuild_for_major_updates_only!
    PublicationLog.with_slug_prefix(@manual_slug).destroy_all

    manual_record = ManualRecord.where(slug: @manual_slug).first
    edition_ordering = EditionOrdering.new(document_editions_for_rebuild, manual_record.latest_edition.document_ids)

    edition_ordering.sort_by_document_ids_and_created_at.each do |edition|
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

  class EditionOrdering
    def initialize(editions, document_ids)
      @editions = editions
      @document_ids = document_ids
    end

    def sort_by_document_ids_and_created_at
      editions_not_matching_supplied_documents = @editions.where(:document_id.nin => @document_ids)
      editions_matching_supplied_documents = @editions.where(:document_id.in => @document_ids)

      order_by_document_ids(editions_matching_supplied_documents).concat(editions_not_matching_supplied_documents.order_by(:created_at, :asc).to_a)
    end

    private

    def order_by_document_ids(editions)
      editions.to_a.sort do |a, b|
        a_index = @document_ids.index(a.document_id)
        b_index = @document_ids.index(b.document_id)

        a_index <=> b_index
      end
    end
  end

  private

  def document_editions_for_rebuild
    SpecialistDocumentEdition.with_slug_prefix(@manual_slug).where(:minor_update.nin => [true]).any_of({state: "published"}, {state: "archived"})
  end
end
