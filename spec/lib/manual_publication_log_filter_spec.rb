require "spec_helper"
require "manual_publication_log_filter"

describe ManualPublicationLogFilter, "# delete_logs_and_rebuild_for_major_updates_only!" do
  let(:manual_slug) { "guidance/the-highway-code" }
  let!(:manual_record) { ManualRecord.create(slug: manual_slug) }
  let(:other_slug) { "guidance/sellotape" }
  let(:document_edition_exported_time) { Time.current }

  let(:document_a_edition_published_version_1_major_update) do
    create(:specialist_document_edition,
           state: "published",
           slug: "#{manual_slug}/first-further-info",
           exported_at: document_edition_exported_time,
           version_number: 1,
          )
  end

  let(:document_a_edition_published_version_2_major_update) do
    create(:specialist_document_edition,
           state: "published",
           slug: document_a_edition_published_version_1_major_update.slug,
           document_id: document_a_edition_published_version_1_major_update.document_id,
           exported_at: document_edition_exported_time,
           version_number: 2
          )
  end

  let(:document_b_edition_published_version_1_major_update) do
    create(:specialist_document_edition,
           state: "published",
           slug: "#{manual_slug}/second-further-info",
           exported_at: document_edition_exported_time,
           version_number: 1,
          )
  end

  let(:document_b_edition_published_version_2_minor_update) do
    create(:specialist_document_edition,
           state: "published",
           slug: document_b_edition_published_version_1_major_update.slug,
           document_id: document_b_edition_published_version_1_major_update.document_id,
           exported_at: document_edition_exported_time,
           minor_update: true,
           version_number: 2
          )
  end

  let(:document_c_edition_archived_version_1_major_update) do
    create(:specialist_document_edition,
           state: "archived",
           slug: "#{manual_slug}/additional-data",
           exported_at: document_edition_exported_time,
           version_number: 1
          )
  end

  let(:document_d_edition_draft_version_1_major_update) do
    create(:specialist_document_edition,
           state: "draft",
           slug: "#{manual_slug}/draft-info",
           exported_at: document_edition_exported_time,
           version_number: 1
          )
  end

  let(:document_e_edition_published_version_1_major_update) do
    create(:specialist_document_edition,
           state: "published",
           slug: "#{manual_slug}/third-further-info",
           exported_at: document_edition_exported_time,
           version_number: 1,
          )
  end

  let!(:previous_publication_logs) { create_list(:publication_log, 2, slug: manual_slug) }
  let!(:previous_other_publication_log) { create :publication_log, slug: other_slug }

  let(:first_manual_edition_creation_time) { Time.current - 1.week }
  let(:second_manual_edition_creation_time) { first_manual_edition_creation_time - 1.day }

  let!(:first_manual_edition) {
    manual_record.editions.create!(
      state: "published",
      version_number: 1,
      document_ids: [
        document_a_edition_published_version_1_major_update.document_id,
        document_b_edition_published_version_1_major_update.document_id,
        document_c_edition_archived_version_1_major_update.document_id,
      ],
      created_at: first_manual_edition_creation_time,
      updated_at: first_manual_edition_creation_time
    )
  }

  let!(:second_manual_edition) {
    manual_record.editions.create!(
      state: "published",
      version_number: 2,
      document_ids: [
        document_a_edition_published_version_2_major_update.document_id,
        document_b_edition_published_version_2_minor_update.document_id,
        document_c_edition_archived_version_1_major_update.document_id,
        document_d_edition_draft_version_1_major_update.document_id,
        document_e_edition_published_version_1_major_update.document_id
      ],
      created_at: second_manual_edition_creation_time,
      updated_at: first_manual_edition_creation_time
    )
  }

  before do
    described_class.new(manual_record).delete_logs_and_rebuild_for_major_updates_only!
  end

  it "deletes all existing publication logs for the supplied manual slug only" do
    expect(PublicationLog.where(_id: previous_publication_logs.first.id).exists?).to eq false
    expect(PublicationLog.where(_id: previous_publication_logs.second.id).exists?).to eq false

    expect(PublicationLog.where(_id: previous_other_publication_log.id).exists?).to eq true
  end

  it "builds logs for major updates in the 'archived' and 'published' status" do
    publication_logs_for_supplied_slug = PublicationLog.with_slug_prefix(manual_slug).order_by(:id, :asc)

    expect(publication_logs_for_supplied_slug.count).to eq 5

    # First versions of document editions should have their associated logs "re-set"
    # to the associated manual edition updated time. There are some cases where such editions have
    # timestamps that post-date the manual edition update time. This is thought
    # to be "wrong" because the first manual and first editions of its documents
    # are expected to all be exported at the same time.
    expect_log_attributes_to_match_edition(publication_logs_for_supplied_slug[0], document_a_edition_published_version_1_major_update, first_manual_edition.updated_at)
    expect_log_attributes_to_match_edition(publication_logs_for_supplied_slug[1], document_b_edition_published_version_1_major_update, first_manual_edition.updated_at)
    expect_log_attributes_to_match_edition(publication_logs_for_supplied_slug[2], document_c_edition_archived_version_1_major_update, first_manual_edition.updated_at)

    # First version which should have its exported_at timestamp set to the
    # associated manual edition
    expect_log_attributes_to_match_edition(publication_logs_for_supplied_slug[3], document_e_edition_published_version_1_major_update, second_manual_edition.updated_at)

    # For document editions with a version number greater than 1, we can only
    # use the exported_at timestamp to use for the publication log as there's no
    # way to link back to the manual edition
    expect_log_attributes_to_match_edition(publication_logs_for_supplied_slug[4], document_a_edition_published_version_2_major_update, document_a_edition_published_version_2_major_update.updated_at)

  end

  def expect_log_attributes_to_match_edition(log, document_edition, expected_time)
    expect(log).to have_attributes(
      slug: document_edition.slug,
      title: document_edition.title,
      version_number: document_edition.version_number,
      change_note: document_edition.change_note,
      created_at: expected_time,
      updated_at: expected_time
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
