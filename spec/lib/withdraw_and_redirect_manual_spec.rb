require "spec_helper"

RSpec.describe WithdrawAndRedirectManual do
  let(:manual_record) { FactoryBot.create(:manual_record, :with_sections, state:) }
  let(:manual) { Manual.build_manual_for(manual_record) }
  let(:section) { manual.sections.last }
  let(:redirect) { "/redirect/blah" }
  let(:discard_drafts) { false }
  let(:state) { "published" }
  let(:user) { User.gds_editor }
  let(:include_sections) { true }
  let(:dry_run) { false }

  let(:discard_service) { double(:discard_service) }
  let(:publishing_adapter) { double(:publishing_adapter) }

  subject do
    described_class.new(
      user:,
      manual_path: manual.slug,
      redirect:,
      include_sections:,
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

  it "withdraws the manual" do
    subject.execute

    reloaded_manual = Manual.find(manual.id, user)
    expect(reloaded_manual.withdrawn?).to eq(true)
  end

  it "calls the publishing adapter to unpublish the manual" do
    subject.execute
    expect(publishing_adapter).to have_received(:unpublish_and_redirect_manual_and_sections)
      .with(instance_of(Manual),
            redirect:,
            include_sections:,
            discard_drafts:)
  end

  context "when there is no published manual" do
    let(:state) { "draft" }

    it "raises an error" do
      expect { subject.execute }.to raise_error(WithdrawAndRedirectManual::ManualNotPublishedError)
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
