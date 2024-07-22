require "spec_helper"

RSpec.describe Manual::WithdrawService do
  let(:user) { User.gds_editor }
  let(:state) { "published" }
  let!(:manual_record) { FactoryBot.create(:manual_record, manual_id: "manual-id", state:) }

  subject do
    described_class.new(user:, manual_id: manual_record.manual_id)
  end

  it "raises error when Manual is not found" do
    expect {
      Manual::WithdrawService.new(user:, manual_id: "non-existant-id").call
    }.to raise_error(Manual::NotFoundError, "Manual ID not found: non-existant-id")
  end

  it "withdraws published manuals" do
    expect(PublishingAdapter).to receive(:unpublish).with(have_attributes(id: manual_record.manual_id)).once
    subject.call
    expect(manual_record.reload.latest_edition.state).to eq("withdrawn")
  end

  context "for already withdrawn manuals" do
    let(:state) { "withdrawn" }
    it "unpublishes" do
      expect(PublishingAdapter).to receive(:unpublish).with(have_attributes(id: manual_record.manual_id)).once
      subject.call
      expect(manual_record.reload.latest_edition.state).to eq("withdrawn")
    end
  end

  context "for archived manuals" do
    let(:state) { "archived" }
    it "does not unpublish archived manuals" do
      expect(PublishingAdapter).to_not receive(:unpublish)
      subject.call
      expect(manual_record.reload.latest_edition.state).to eq("archived")
    end
  end

  context "for draft only manuals" do
    let(:state) { "draft" }
    it "does not unpublish" do
      expect(PublishingAdapter).to_not receive(:unpublish)
      subject.call
      expect(manual_record.reload.latest_edition.state).to eq("draft")
    end
  end

  context "for published with draft manuals" do
    it "does not unpublish" do
      Manual.build_manual_for(manual_record).draft.save!(user)
      expect(PublishingAdapter).to_not receive(:unpublish)

      subject.call

      editions = manual_record.reload.editions
      expect(editions[0].state).to eq("published")
      expect(editions[1].state).to eq("draft")
    end
  end
end
