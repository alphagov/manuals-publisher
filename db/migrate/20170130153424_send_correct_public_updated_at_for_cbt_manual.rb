# The History
# -----------
#
# As part of a story to remove change notes for minor editions from the
# publishing-api we asked the users to check the published versions of
# their manuals to see if the new change history was correct.  The owner
# of the CBT syllabus and guidance manual (content_id:
# ccf91c4f-6a0f-4498-8ddd-6be537df296c) let us know that the public
# timestamp was set to 14th Nov 2016, when they were sure the manual was
# actually published on 1st Dec 2016.  We investigated and noticed that
# some the first_published_at was in line with what they expected (1st
# Dec 2016) but the public_updated_at was somehow set to the 14th Nov
# 2016.
#
# We can't work out why this happened, as none of the scripts run to
# tidy up change notes made changes to the public_updated_at timestamp
# of the manuals.  The only thing we can think is that somehow the
# timestamp was set as part of a mistaken early publish and never updated
# afterwards.
#
# This Migration issues publishing-api commands to set the
# public_updated_at to 1st Dec 2016.
#
# Note that we only need to set the correct timestamp on the manual
# not it's documents, as only the manual timestamp is used.
class SendCorrectPublicUpdatedAtForCbtManual < Mongoid::Migration
  def self.up
    correct_public_timestamp = Time.zone.parse("2016-12-01T08:51:37.000+00:00")

    manual, _metadata_we_dont_need_here = ManualServiceRegistry.new.show("ccf91c4f-6a0f-4498-8ddd-6be537df296c").call
    publishing_api = ManualsPublisherWiring.get(:publishing_api_v2)

    put_content = ->(content_id, payload) do
      publishing_api.put_content(content_id, payload.merge(
        public_updated_at: correct_public_timestamp,
        first_published_at: correct_public_timestamp,
        update_type: "republish"
      ))
    end

    # Write new drafts of the manual
    manual_renderer = ManualRenderer.create
    organisation = ManualsPublisherWiring.get(:organisation_fetcher).call(manual.organisation_slug)
    ManualPublishingAPIExporter.new(
      put_content, organisation, manual_renderer, PublicationLog, manual
    ).call

    # Publish the new draft
    publishing_api.publish(manual.id, "republish")
  end

  def self.down
    # We can't undo this as the change lives only in the publishing-api
    raise IrreversibleMigration
  end
end
