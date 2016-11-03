require "spec_helper"
require "manual_publication_log_filter"

describe ManualPublicationLogFilter, "# delete_logs_and_rebuild_for_major_updates_only!" do
  let(:manual_slug) { "guidance/the-highway-code" }
  let(:other_slug) { "guidance/sellotape" }
  let(:exported_time) { Time.current }

  let!(:published_major_update_document_edition) do
    create(:specialist_document_edition,
           state: "published",
           slug: "#{manual_slug}/further-info",
           exported_at: exported_time - 1.day
          )
  end

  let!(:archived_major_update_document_edition) do
    create(:specialist_document_edition,
           state: "archived",
           slug: "#{manual_slug}/additional-data",
           exported_at: exported_time - 2.days
          )
  end

  let!(:draft_major_update_document_edition) do
    create(:specialist_document_edition,
           state: "draft",
           slug: "#{manual_slug}/draft-info",
           exported_at: exported_time - 3.days
          )
  end

  let!(:published_minor_update_document_edition) do
    create(:specialist_document_edition,
           state: "published",
           slug: "#{manual_slug}/further-info",
           minor_update: true
          )
  end

  let!(:previous_publication_logs) { create_list(:publication_log, 2, slug: manual_slug) }
  let!(:previous_other_publication_log) { create :publication_log, slug: other_slug }

  before do
    subject.delete_logs_and_rebuild_for_major_updates_only!(manual_slug)
  end

  it "deletes all existing publication logs for the supplied manual slug only" do
    expect(PublicationLog.where(_id: previous_publication_logs.first.id).exists?).to eq false
    expect(PublicationLog.where(_id: previous_publication_logs.second.id).exists?).to eq false

    expect(PublicationLog.where(_id: previous_other_publication_log.id).exists?).to eq true
  end

  it "builds logs for major updates in the 'archived' and 'published' status only" do
    publication_logs_for_supplied_slug = PublicationLog.with_slug_prefix(manual_slug)

    expect(publication_logs_for_supplied_slug.count).to eq 2

    expect_log_attributes_to_match_edition(PublicationLog.where(slug: published_major_update_document_edition.slug).first, published_major_update_document_edition)
    expect_log_attributes_to_match_edition(PublicationLog.where(slug: archived_major_update_document_edition.slug).first, archived_major_update_document_edition)
  end

  def expect_log_attributes_to_match_edition(log, edition)
    expect(log).to have_attributes(
      slug: edition.slug,
      title: edition.title,
      version_number: edition.version_number,
      change_note: edition.change_note,
      created_at: edition.exported_at,
      updated_at: edition.exported_at
    )
  end
end
