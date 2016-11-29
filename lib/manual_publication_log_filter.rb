class ManualPublicationLogFilter
  def initialize(manual_record)
    @manual_record = manual_record
    @manual_slug = manual_record.slug
  end

  def delete_logs_and_rebuild_for_major_updates_only!
    PublicationLog.with_slug_prefix(@manual_slug).destroy_all

    build_logs_for_all_first_document_editions_at_manual_edition_time
    build_logs_for_all_other_suitable_document_editions
  end

  class EditionOrdering
    def initialize(document_editions, document_ids)
      @document_editions = document_editions
      @document_ids = document_ids
    end

    def sort_by_document_ids_and_created_at
      editions_not_matching_supplied_documents = @document_editions.where(:document_id.nin => @document_ids)
      editions_matching_supplied_documents = @document_editions.where(:document_id.in => @document_ids)

      order_by_document_ids(editions_matching_supplied_documents).concat(editions_not_matching_supplied_documents.order_by(:created_at, :asc).to_a)
    end

    private

    def order_by_document_ids(document_editions)
      document_editions.to_a.sort do |a, b|
        a_index = @document_ids.index(a.document_id)
        b_index = @document_ids.index(b.document_id)

        a_index <=> b_index
      end
    end
  end

  private

  def build_logs_for_all_first_document_editions_at_manual_edition_time
    # 1. Log all document editions for the first manual with a version number 1
    published_first_document_edition_document_ids = document_editions_for_first_manual_edition.map do |document_edition|
      PublicationLog.create!(
        title: document_edition.title,
        slug: document_edition.slug,
        version_number: document_edition.version_number,
        change_note: document_edition.change_note,
        created_at: first_manual_edition.updated_at,
        updated_at: first_manual_edition.updated_at
      )

      document_edition.document_id
    end

    # 2. Log all suitable subsequent document editions if we infer that they are the first version
    @manual_record.editions.where(:version_number.nin => [1]).order_by(:version_number).each do |manual_edition|
      manual_edition.document_ids.each do |document_id|
        next if published_first_document_edition_document_ids.include? document_id

        # This is the first time we've encountered this document id when examining
        # in chronological manual edition order. We get hold of the first document
        # edition and construct the log using the manual edition updated time. We do this because
        # the exported time of the first editions appears to be untrustworthy
        # (they can sometimes post-date the manual edition updated timestamp).
        #
        # We trust the manual edition updated timestamp more, so we set the
        # publication log timestamp to that.
        first_document_edition = SpecialistDocumentEdition.where(document_id: document_id, version_number: 1).first

        next if !first_document_edition || first_document_edition.state == "draft" || first_document_edition.minor_update?

        PublicationLog.create!(
          title: first_document_edition.title,
          slug: first_document_edition.slug,
          version_number: first_document_edition.version_number,
          change_note: first_document_edition.change_note,
          created_at: manual_edition.updated_at,
          updated_at: manual_edition.updated_at
        )

        # We've done our custom logging for this first edition. Now store it so
        # we can check we don't create the same first document edition log again.
        published_first_document_edition_document_ids << document_id
      end
    end
  end

  def build_logs_for_all_other_suitable_document_editions
    edition_ordering = EditionOrdering.new(document_editions_for_rebuild, @manual_record.latest_edition.document_ids)

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

  def document_editions_for_first_manual_edition
    SpecialistDocumentEdition.where(:document_id.in => first_manual_edition.document_ids, :minor_update.nin => [true], version_number: 1).any_of({state: "published"}, { state: "archived"})
  end

  def first_manual_edition
    @first_manual_edition ||= @manual_record.editions.where(version_number: 1).first
  end

  def document_editions_for_rebuild
    SpecialistDocumentEdition.with_slug_prefix(@manual_slug).where(:minor_update.nin => [true], :version_number.nin => [1]).any_of({state: "published"}, {state: "archived"})
  end
end
