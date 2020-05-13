require "spec_helper"

describe ManualRecord, hits_db: true do
  subject(:record) { ManualRecord.create }

  describe "#latest_edition" do
    context "when there are several previous editions" do
      let!(:editions) do
        [
          record.editions.create!(state: "published", version_number: 2),
          record.editions.create!(state: "draft", version_number: 3),
          record.editions.create!(state: "published", version_number: 1),
        ]
      end

      it "returns the edition with the highest version number" do
        expect(record.latest_edition.version_number).to eq(3)
      end

      it "returns the most recent new draft even if it hasn't been saved yet" do
        # make everything published
        record.editions.each { |e| e.update!(state: "published") }
        # build a new draft
        new_draft = record.new_or_existing_draft_edition
        expect(new_draft).not_to be_persisted
        expect(record.latest_edition).to eq(new_draft)
      end
    end
  end

  context "saving" do
    it "saves the latest edition if it needs saving" do
      new_draft = record.new_or_existing_draft_edition
      record.save!
      expect(new_draft).to be_persisted
    end
  end

  describe "#new_or_existing_draft_edition" do
    context "when a draft edition exists" do
      let!(:edition) { record.editions.create!(state: "draft") }

      it "returns the existing draft edition" do
        expect(record.new_or_existing_draft_edition).to eq(edition)
      end
    end

    context "when both published and draft editions exist" do
      before do
        @draft_edition = record.editions.create!(state: "draft", version_number: 2)
        record.editions.create!(state: "published", version_number: 1)
      end

      it "returns the existing draft edition" do
        expect(record.new_or_existing_draft_edition).to eq(@draft_edition)
      end
    end

    context "when no editions exist" do
      it "builds a new draft edition" do
        new_edition = record.new_or_existing_draft_edition
        expect(new_edition).not_to be_persisted
        expect(new_edition.state).to eq("draft")
        expect(new_edition.version_number).to eq(1)
      end
    end

    context "when only non-draft editions exists" do
      before do
        record.editions.create!(state: "published", version_number: 1)
      end

      it "builds a new draft edition" do
        new_edition = record.new_or_existing_draft_edition
        expect(new_edition).not_to be_persisted
        expect(new_edition.state).to eq("draft")
        expect(new_edition.version_number).to eq(2)
      end
    end
  end

  describe "#all_by_updated_at" do
    let!(:middle_edition) do
      ManualRecord.create!(updated_at: 2.days.ago)
    end

    let!(:early_edition) do
      ManualRecord.create!(updated_at: 3.days.ago)
    end

    let!(:later_edition) do
      ManualRecord.create!(updated_at: 1.day.ago)
    end

    it "returns manuals ordered with most recently updated first" do
      expect(ManualRecord.all_by_updated_at.to_a).to eq([later_edition, middle_edition, early_edition])
    end
  end

  describe "#has_ever_been_published?" do
    it "is false for an unsaved instance" do
      expect(ManualRecord.new).not_to have_ever_been_published
    end

    it "is false for a saved instance with no editions" do
      expect(record).not_to have_ever_been_published
    end

    it "is false for a saved instance with no published editions" do
      record.editions.create!(state: "draft", version_number: 1)
      record.editions.create!(state: "withdrawn", version_number: 2)
      record.editions.create!(state: "draft", version_number: 3)
      expect(subject).not_to have_ever_been_published
    end

    it "is true for a saved instance with a published edition" do
      record.editions.create!(state: "published", version_number: 1)
      expect(subject).to have_ever_been_published
    end

    it "is true for a saved instance with any published editions even if it's not the latest" do
      record.editions.create!(state: "draft", version_number: 1)
      record.editions.create!(state: "published", version_number: 2)
      record.editions.create!(state: "withdrawn", version_number: 3)
      record.editions.create!(state: "draft", version_number: 4)
      expect(subject).to have_ever_been_published
    end
  end
end
