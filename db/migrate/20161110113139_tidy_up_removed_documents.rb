# The history
# ===========
#
# Following on from the previous migration where we deleted ids from the
# removed_document_ids field, now we need to make sure that the documents
# referred to by the remaining entries have been correctly withdrawn as if
# the new removal functionality had been in place.
#
# This means setting the state to archived and discarding drafts from the
# publishing-api for any documents in 'draft' state, and creating a new
# edition that we archive and send an unpublishing to the publishing-api.
require "rummager_indexer"
require "formatters/manual_section_indexable_formatter"

class TidyUpRemovedDocuments < Mongoid::Migration
  def self.up
    ManualRecord.all.to_a.each do |manual_record|
      puts %{Collecting removed_document_editons from "#{manual_record.slug}":#{manual_record.manual_id}}
      removed_document_ids = manual_record.editions.map { |manual_edition|
        manual_edition.removed_document_ids || []
      }.flatten.uniq
      puts %{Found #{removed_document_ids.count} removed documents}
      removed_document_ids.each do |document_id|
        puts "Tidying up #{document_id}"
        tidy_up(manual_record, document_id, SpecialistDocumentEdition.where(document_id: document_id).order_by(version_number: :asc).to_a)
      end
    end
  end

  def self.tidy_up(manual, document_id, all_editions)
    # This method is basically all the things that would happen when you remove
    # a section and then publish.  We don't need to write a new draft of
    # the manual to remove the document from the child_sections though as that
    # will have already happened.  Neither do we need to write the
    # PublicationLog entries because adding a change note while removing a
    # section is a feature added since these were removed, any change_notes
    # on these editions will already be in the PublicationLog if they should be
    # there.
    current_edition = all_editions.last

    # Part 1 - tidy up external services
    # a. discard the draft in the publishing-api
    #    see: AbstractManualDocumentServiceRegistry#remove (publishing_api_draft_manual_document_discarder)
    begin
      publishing_api_v2.discard_draft(document_id)
    rescue GdsApi::HTTPNotFound, GdsApi::HTTPUnprocessableEntity
    end
    # b. unpublish the document with a redirect back to the manual
    #    see: ManualObserversRegistry#publish (publishing_api_publisher)
    begin
      publishing_api_v2.unpublish(document_id, { type: "redirect", alternative_path: "/#{manual.slug}", discard_drafts: true })
    rescue GdsApi::HTTPNotFound
    end
    # c. Remove it from rummager
    #    see: ManualObserversRegistry#publish (rummager_exporter)
    RummagerIndexer.new.delete(ManualSectionIndexableFormatter.new(current_edition, manual))

    # Part 2 - tidy up our database
    # a. build a new draft if the current edition is published
    #    see: RemoveManualDocumentService#call (SpecialistDocumentEdition#update)
    if current_edition.published?
      current_edition = build_new_draft(document_id, current_edition)
    end
    # b. mark the current edition as exported and archive it
    #    see: ManualObserversRegistry#publish (publishing_api_publisher)
    current_edition.exported_at = Time.zone.now
    current_edition.archive
  end

  def self.build_new_draft(document_id, edition)
    # This cobbled together from SpecialistDocument#new_draft
    previous_edition_attributes = edition.attributes.
      except("_id", "created_at", "updated_at", "exported_at").
      symbolize_keys
    new_edition_attributes = previous_edition_attributes
      .merge(
        minor_update: true,
        change_note: "",
        state: "draft",
        document_id: document_id,
        version_number: edition.version_number + 1,
        slug: edition.slug,
        document_type: edition.document_type,
        attachments: edition.attachments.to_a,
      )

    SpecialistDocumentEdition.new(new_edition_attributes)
  end

  def self.publishing_api_v2
    ManualsPublisherWiring.get(:publishing_api_v2)
  end

  def self.down
    # Whilst it would be possible to reverse this, it would be a lot of work
    # for something that is unlikely to ever get run.
    raise IrreversibleMigration
  end
end
