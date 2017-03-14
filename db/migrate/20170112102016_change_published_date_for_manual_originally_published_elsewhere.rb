# The history
# ===========
#
# The National Planning Policy Framework manual was originally published
# in March 2012, and recently migrated over to GOV.UK.  The version now
# published says it was updated on in Dec 2016 as that's when it was
# first published to GOV.UK, however, no changes were made to the content
# and this date is causing users of the manual to get in touch to find
# out what has changed.  The app doesn't (yet) have the ability to override
# the dates in the UI, nor does it have the ability to set the change
# notes for sections when they are first created.
#
# What we'll do here is edit the change notes to read "Imported to GOV.UK"
# instead of "New section added" and republish the manual and it's sections
# so that the public_updated_at is explicitly set to the original publication
# date in March 2012.
class ChangePublishedDateForManualOriginallyPublishedElsewhere < Mongoid::Migration
  def self.up
    manual = ManualRecord.find_by(slug: "guidance/national-planning-policy-framework")
    document_ids = manual.editions.flat_map(&:document_ids).uniq

    # Get all the document_editions
    all_sections = SpecialistDocumentEdition.where(:document_id.in => document_ids)
    first_editions, other_editions = all_sections.partition { |edition| edition.version_number == 1 }

    # Set change note for all first editions to "Imported to GOV.UK"
    first_editions.map do |edition|
      edition.update_attributes(change_note: "Imported to GOV.UK.")
      log = PublicationLog.where(slug: edition.slug, version_number: edition.version_number).first
      log.update_attributes(change_note: "Imported to GOV.UK.") if log.present?
    end

    # Set all other editions to minor and remove their change notes, if they're
    # major and the change note is the default "New section added."
    other_editions.map do |edition|
      if (!edition.minor_update) && (edition.change_note == "New section added.")
        edition.update_attributes(minor_update: true, change_note: "")
        log = PublicationLog.where(slug: edition.slug, version_number: edition.version_number).first
        log.destroy if log.present?
      end
    end

    # Do all the prep work to make it so we can republish the manual and its
    # sections, while injecting the old publish date
    original_publish_date = Date.new(2012, 3, 27).to_time
    publishing_api = PublishingApiV2.instance
    organisation = OrganisationFetcher.instance.call(manual.organisation_slug)
    manual_renderer = ManualRenderer.create
    manual_document_renderer = ManualDocumentRenderer.create

    manual_for_publishing, _metadata_we_dont_need_here = ManualServiceRegistry.new.show(manual.manual_id).call

    # Inject the original publish date as the first_published_at and make the
    # new draft a minor update (so publishing-api doesn't get any ideas about
    # timestamps itself).
    put_content = ->(content_id, payload) do
      publishing_api.put_content(content_id, payload.merge(
        public_updated_at: original_publish_date,
        first_published_at: original_publish_date,
        update_type: "minor"
      ))
    end

    # Write new drafts of the manual and it's documents
    ManualPublishingAPIExporter.new(
      put_content, organisation, manual_renderer, PublicationLog, manual_for_publishing
    ).call
    manual_for_publishing.documents.each do |manual_document|
      SectionPublishingAPIExporter.new(
        put_content, organisation, manual_document_renderer, manual_for_publishing, manual_document
      ).call
    end

    # Publish these new drafts
    publishing_api.publish(manual_for_publishing.id, "republish")
    manual_for_publishing.documents.each do |manual_document|
      publishing_api.publish(manual_document.id, "republish")
    end
  end

  def self.down
    # It's not really possible to reverse this as some of the above
    # changes are destructive.
    raise IrreversibleMigration
  end
end
