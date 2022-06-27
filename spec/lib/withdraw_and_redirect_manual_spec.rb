require "spec_helper"

RSpec.describe WithdrawAndRedirectManual do
  let(:manual_record) { FactoryBot.create(:manual_record, :with_sections, state: state) }
  let(:manual) { Manual.build_manual_for(manual_record) }
  let(:section) { manual.sections.last }
  let(:redirect) { "/redirect/blah" }
  let(:discard_drafts) { false }
  let(:state) { "published" }
  let(:user) { User.gds_editor }
  let(:include_sections) { true }

  let(:discard_service) { double(:discard_service) }
  let(:publishing_adapter) { double(:publishing_adapter) }

  subject do
    described_class.new(
      user: user,
      manual_path: manual.slug,
      redirect: redirect,
      include_sections: include_sections,
      discard_drafts: discard_drafts,
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
            redirect: redirect,
            include_sections: include_sections,
            discard_drafts: discard_drafts)
  end

  context "when there is no published manual" do
    let(:state) { "draft" }

    it "raises an error" do
      expect { subject.execute }.to raise_error(WithdrawAndRedirectManual::ManualNotPublishedError)
    end
  end
end
