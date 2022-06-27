require "spec_helper"

RSpec.describe WithdrawAndRedirectSection do
  let(:manual_record) { FactoryBot.create(:manual_record, :with_sections, state: state) }
  let(:manual) { Manual.build_manual_for(manual_record) }
  let(:section) { manual.sections.last }
  let(:publishing_adapter) { double(:publishing_adapter) }
  let(:redirect) { "/redirect/blah" }
  let(:discard_draft) { false }
  let(:state) { "published" }

  subject do
    described_class.new(
      user: User.gds_editor,
      manual_path: manual.slug,
      section_path: manual.sections.last.slug,
      redirect: redirect,
      discard_draft: discard_draft,
    )
  end

  before do
    allow(Adapters).to receive(:publishing) { publishing_adapter }
    allow(publishing_adapter).to receive(:unpublish_section)
  end

  it "calls the publishing adapter to unpublish the section" do
    subject.execute
    expect(publishing_adapter).to have_received(:unpublish_section)
      .with(instance_of(Section),
            redirect: redirect,
            discard_drafts: discard_draft)
  end

  context "when only a draft section exists" do
    let(:state) { "draft" }

    it "raises an error if section is not published" do
      expect { subject.execute }.to raise_error(WithdrawAndRedirectSection::SectionNotPublishedError)
    end
  end

  context "when an accompanying drafts exists and discard_draft is flagged" do
    let(:discard_draft) { true }

    it "discards draft" do
      manual.draft
      section.assign_attributes({})
      manual.save!(User.gds_editor)

      subject.execute
      expect(publishing_adapter).to have_received(:unpublish_section)
        .with(instance_of(Section),
              redirect: redirect,
              discard_drafts: discard_draft)
    end
  end
end
