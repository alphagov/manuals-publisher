require "spec_helper"

RSpec.describe WithdrawAndRedirectManual do
  let(:manual_record) { FactoryBot.create(:manual_record, :with_sections, state:) }
  let(:manual) { Manual.build_manual_for(manual_record) }
  let(:section) { manual.sections.last }
  let(:redirect) { "/redirect/blah" }
  let(:discard_drafts) { false }
  let(:state) { "published" }
  let(:user) { User.gds_editor }
  let(:dry_run) { false }

  let(:discard_service) { double(:discard_service) }
  let(:publishing_adapter) { double(:publishing_adapter) }

  subject do
    described_class.new(
      user:,
      manual_path: manual.slug,
      redirect:,
      discard_drafts:,
      dry_run:,
    )
  end

  before do
    allow(Manual::DiscardDraftService).to receive(:new) { discard_service }
    allow(discard_service).to receive(:call)

    allow(Adapters).to receive(:publishing) { publishing_adapter }
    allow(publishing_adapter).to receive(:unpublish_and_redirect_manual_and_sections)
  end

  it "withdraws the manual and unpublishes" do
    subject.execute

    reloaded_manual = Manual.find(manual.id, user)
    expect(reloaded_manual.withdrawn?).to eq(true)
    expect(publishing_adapter).to have_received(:unpublish_and_redirect_manual_and_sections)
                                    .with(instance_of(Manual),
                                          redirect:,
                                          discard_drafts:)
  end

  context "when the manual is in draft" do
    let(:state) { "draft" }

    it "raises an error" do
      expect { subject.execute }.to raise_error(WithdrawAndRedirectManual::ManualNotPublishedError)
    end
  end

  context "when the manual is withdrawn" do
    it "withdraws and unpublishes the manual again" do
      manual.withdraw
      manual.save!(user)

      subject.execute

      reloaded_manual = Manual.find(manual.id, user)
      expect(reloaded_manual.withdrawn?).to eq(true)
      expect(publishing_adapter).to have_received(:unpublish_and_redirect_manual_and_sections)
                                      .with(instance_of(Manual),
                                            redirect:,
                                            discard_drafts:)
    end
  end

  context "when a dry run is flagged" do
    let(:dry_run) { true }

    it "doesn't action the withdrawal" do
      subject.execute
      expect(publishing_adapter).to_not have_received(:unpublish_and_redirect_manual_and_sections)
    end
  end
end
