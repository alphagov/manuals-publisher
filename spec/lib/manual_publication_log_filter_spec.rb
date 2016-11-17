require "spec_helper"
require "manual_publication_log_filter"

describe ManualPublicationLogFilter, "# delete_logs_and_rebuild_for_major_updates_only!" do
  let(:manual_slug) { "guidance/the-highway-code" }
  let!(:manual_record) { ManualRecord.create(slug: manual_slug) }
  let(:other_slug) { "guidance/sellotape" }
  let(:exported_time) { Time.current }

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
           slug: "#{manual_slug}/first-further-info",
           minor_update: true
          )
  end

  let!(:published_major_update_document_edition_1) do
    create(:specialist_document_edition,
           state: "published",
           slug: "#{manual_slug}/first-further-info",
           exported_at: exported_time - 1.day
          )
  end

  let!(:published_major_update_document_edition_2) do
    create(:specialist_document_edition,
           state: "published",
           slug: "#{manual_slug}/second-further-info",
           exported_at: exported_time - 1.day
          )
  end

  let!(:previous_publication_logs) { create_list(:publication_log, 2, slug: manual_slug) }
  let!(:previous_other_publication_log) { create :publication_log, slug: other_slug }

  before do
    manual_record.editions.create!(
      state: "published",
      version_number: 1,
      document_ids: [
        published_major_update_document_edition_1.document_id,
        archived_major_update_document_edition.document_id,
        published_major_update_document_edition_2.document_id
      ]
    )

    manual_record.editions.create!(
      state: "published",
      version_number: 2,
      document_ids: [
        published_major_update_document_edition_1.document_id,
        published_major_update_document_edition_2.document_id,
        archived_major_update_document_edition.document_id,
      ]
    )

    subject.delete_logs_and_rebuild_for_major_updates_only!(manual_slug)
  end

  it "deletes all existing publication logs for the supplied manual slug only" do
    expect(PublicationLog.where(_id: previous_publication_logs.first.id).exists?).to eq false
    expect(PublicationLog.where(_id: previous_publication_logs.second.id).exists?).to eq false

    expect(PublicationLog.where(_id: previous_other_publication_log.id).exists?).to eq true
  end

  it "builds logs for major updates in the 'archived' and 'published' status only in the same order as the documents on the most recent manual" do
    publication_logs_for_supplied_slug = PublicationLog.with_slug_prefix(manual_slug).order_by(:id, :asc)

    expect(publication_logs_for_supplied_slug.count).to eq 3

    expect_log_attributes_to_match_edition(publication_logs_for_supplied_slug[0], published_major_update_document_edition_1)
    expect_log_attributes_to_match_edition(publication_logs_for_supplied_slug[1], published_major_update_document_edition_2)
    expect_log_attributes_to_match_edition(publication_logs_for_supplied_slug[2], archived_major_update_document_edition)
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

describe ManualPublicationLogFilter::EditionOrdering do
  describe ".sort_by_document_ids_and_created_at" do
    let!(:edition_in_third_position) { create :specialist_document_edition }
    let!(:edition_in_first_position) { create :specialist_document_edition }
    let!(:edition_in_second_position) { create :specialist_document_edition }

    let!(:other_edition_newer) { create :specialist_document_edition, created_at: Time.now - 1.day }
    let!(:other_edition_older) { create :specialist_document_edition, created_at: Time.now - 1.week }

    let!(:document_ids) {
      [
        edition_in_first_position.document_id,
        edition_in_second_position.document_id,
        edition_in_third_position.document_id,
      ]
    }

    let(:expected_document_order) {
      document_ids.concat([other_edition_older.document_id, other_edition_newer.document_id])
    }

    let(:subject) { described_class.new(SpecialistDocumentEdition.all, document_ids) }

    it "returns editions in the supplied document id and created_at order" do
      ordered_editions = subject.sort_by_document_ids_and_created_at

      expect(ordered_editions.map(&:document_id)).to eq expected_document_order
    end
  end
end
