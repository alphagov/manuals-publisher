require "spec_helper"
require "manual_publication_log_filter"

describe ManualPublicationLogFilter, "# delete_logs_and_rebuild_for_major_updates_only!" do
  let(:manual_slug) { "guidance/the-highway-code" }
  let!(:manual_record) { ManualRecord.create(slug: manual_slug) }
  let(:other_slug) { "guidance/sellotape" }
  let(:section_edition_exported_time) { Time.current }

  let(:section_a_edition_published_version_1_major_update) do
    FactoryGirl.create(
      :section_edition,
      state: "published",
      slug: "#{manual_slug}/first-further-info",
      exported_at: section_edition_exported_time,
      version_number: 1,
    )
  end

  let(:section_a_edition_published_version_2_major_update) do
    FactoryGirl.create(
      :section_edition,
      state: "published",
      slug: section_a_edition_published_version_1_major_update.slug,
      section_id: section_a_edition_published_version_1_major_update.section_id,
      exported_at: section_edition_exported_time,
      version_number: 2
    )
  end

  let(:section_b_edition_published_version_1_major_update) do
    FactoryGirl.create(
      :section_edition,
      state: "published",
      slug: "#{manual_slug}/second-further-info",
      exported_at: section_edition_exported_time,
      version_number: 1,
    )
  end

  let(:section_b_edition_published_version_2_minor_update) do
    FactoryGirl.create(
      :section_edition,
      state: "published",
      slug: section_b_edition_published_version_1_major_update.slug,
      section_id: section_b_edition_published_version_1_major_update.section_id,
      exported_at: section_edition_exported_time,
      minor_update: true,
      version_number: 2
    )
  end

  let(:section_c_edition_archived_version_1_major_update) do
    FactoryGirl.create(
      :section_edition,
      state: "archived",
      slug: "#{manual_slug}/additional-data",
      exported_at: section_edition_exported_time,
      version_number: 1
    )
  end

  let(:section_d_edition_draft_version_1_major_update) do
    FactoryGirl.create(
      :section_edition,
      state: "draft",
      slug: "#{manual_slug}/draft-info",
      exported_at: section_edition_exported_time,
      version_number: 1
    )
  end

  let(:section_e_edition_published_version_1_major_update) do
    FactoryGirl.create(
      :section_edition,
      state: "published",
      slug: "#{manual_slug}/third-further-info",
      exported_at: section_edition_exported_time,
      version_number: 1,
    )
  end

  let!(:previous_publication_logs) {
    [
      FactoryGirl.create(:publication_log, slug: manual_slug, created_at: 10.seconds.ago, version_number: 1),
      FactoryGirl.create(:publication_log, slug: manual_slug, created_at: 8.seconds.ago, version_number: 2)
    ]
  }
  let!(:previous_other_publication_log) {
    FactoryGirl.create :publication_log, slug: other_slug, created_at: 6.seconds.ago, version_number: 1
  }

  let(:first_manual_edition_creation_time) { Time.current - 1.week }
  let(:second_manual_edition_creation_time) { first_manual_edition_creation_time - 1.day }

  let!(:first_manual_edition) {
    manual_record.editions.create!(
      state: "published",
      version_number: 1,
      section_ids: [
        section_a_edition_published_version_1_major_update.section_id,
        section_b_edition_published_version_1_major_update.section_id,
        section_c_edition_archived_version_1_major_update.section_id,
      ],
      created_at: first_manual_edition_creation_time,
      updated_at: first_manual_edition_creation_time
    )
  }

  let!(:second_manual_edition) {
    manual_record.editions.create!(
      state: "published",
      version_number: 2,
      section_ids: [
        section_a_edition_published_version_2_major_update.section_id,
        section_b_edition_published_version_2_minor_update.section_id,
        section_c_edition_archived_version_1_major_update.section_id,
        section_d_edition_draft_version_1_major_update.section_id,
        section_e_edition_published_version_1_major_update.section_id
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
    publication_logs_for_supplied_slug = PublicationLog.with_slug_prefix(manual_slug).order_by([:_id, :asc])

    expect(publication_logs_for_supplied_slug.count).to eq 5

    # First versions of section editions should have their associated logs "re-set"
    # to the associated manual edition updated time. There are some cases where such editions have
    # timestamps that post-date the manual edition update time. This is thought
    # to be "wrong" because the first manual and first editions of its sections
    # are expected to all be exported at the same time.

    # NOTE: we compare using match_array because the timestamps are all the same
    # for the first 3 and last 2 entries which means we can't guarantee the
    # ordering of those two sets.

    publication_logs_for_first_manual_edition = publication_logs_for_supplied_slug[0..2].map { |pl| extract_attributes_from_log(pl) }
    expect(publication_logs_for_first_manual_edition).to match_array([
      build_attributes_for_expected_log(section_a_edition_published_version_1_major_update, first_manual_edition.updated_at),
      build_attributes_for_expected_log(section_b_edition_published_version_1_major_update, first_manual_edition.updated_at),
      build_attributes_for_expected_log(section_c_edition_archived_version_1_major_update, first_manual_edition.updated_at),
    ])

    publication_logs_for_next_editions = publication_logs_for_supplied_slug[3..4].map { |pl| extract_attributes_from_log(pl) }
    expect(publication_logs_for_next_editions).to match_array([
      build_attributes_for_expected_log(section_a_edition_published_version_2_major_update, section_a_edition_published_version_2_major_update.exported_at),
      build_attributes_for_expected_log(section_e_edition_published_version_1_major_update, section_e_edition_published_version_1_major_update.exported_at),
    ])
  end

  def extract_attributes_from_log(log)
    {
      slug: log.slug,
      title: log.title,
      version_number: log.version_number,
      change_note: log.change_note,
      created_at: log.created_at,
      updated_at: log.updated_at,
    }
  end

  def build_attributes_for_expected_log(section_edition, expected_time)
    {
      slug: section_edition.slug,
      title: section_edition.title,
      version_number: section_edition.version_number,
      change_note: section_edition.change_note,
      created_at: expected_time,
      updated_at: expected_time
    }
  end
end

describe ManualPublicationLogFilter::EditionOrdering do
  describe ".sort_by_section_ids_and_created_at" do
    let!(:edition_in_third_position) { FactoryGirl.create :section_edition }
    let!(:edition_in_first_position) { FactoryGirl.create :section_edition }
    let!(:edition_in_second_position) { FactoryGirl.create :section_edition }

    let!(:other_edition_newer) { FactoryGirl.create :section_edition, created_at: Time.now - 1.day }
    let!(:other_edition_older) { FactoryGirl.create :section_edition, created_at: Time.now - 1.week }

    let!(:section_ids) {
      [
        edition_in_first_position.section_id,
        edition_in_second_position.section_id,
        edition_in_third_position.section_id,
      ]
    }

    let(:expected_section_order) {
      section_ids.concat([other_edition_older.section_id, other_edition_newer.section_id])
    }

    let(:subject) { described_class.new(SectionEdition.all, section_ids) }

    it "returns editions in the supplied section id and created_at order" do
      ordered_editions = subject.sort_by_section_ids_and_created_at

      expect(ordered_editions.map(&:section_id)).to eq expected_section_order
    end
  end
end
