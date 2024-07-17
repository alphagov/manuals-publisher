require "spec_helper"

RSpec.describe WithdrawAndRedirectSection do
  let(:manual_record) { FactoryBot.create(:manual_record, :with_sections, state:) }
  let(:manual) { Manual.build_manual_for(manual_record) }
  let(:section) { manual.sections.last }
  let(:redirect) { "/redirect/blah" }
  let(:discard_draft) { false }
  let(:state) { "published" }
  let(:dry_run) { false }

  subject do
    described_class.new(
      user: User.gds_editor,
      manual_path: manual.slug,
      section_path: manual.sections.last.slug,
      redirect:,
      discard_draft:,
      dry_run:,
    )
  end

  it "calls the publishing adapter to unpublish the section" do
    expect(PublishingAdapter).to receive(:unpublish_section)
                                   .with(instance_of(Section),
                                         redirect:,
                                         discard_drafts: discard_draft)
    subject.execute
  end

  context "when only a draft section exists" do
    let(:state) { "draft" }

    it "raises an error if section is not published" do
      expect { subject.execute }.to raise_error(WithdrawAndRedirectSection::SectionNotPublishedError)
    end
  end

  context "when a new draft exists for a published section" do
    before do
      manual.draft
      section.assign_attributes({})
      manual.save!(User.gds_editor)
    end

    context "when discard draft is true" do
      let(:discard_draft) { true }

      it "send discards draft in Publishing API and deletes the draft in manuals publisher" do
        expect(Services.publishing_api).to receive(:unpublish)
                                             .with(section.uuid,
                                                   type: "redirect",
                                                   alternative_path: redirect,
                                                   discard_drafts: true)
        subject.execute
        expect(SectionEdition.where(section_uuid: section.uuid).pluck(:state)).to eq(["archived"])
      end
    end

    context "when discard_draft is false" do
      let(:discard_draft) { false }

      it "sends allow draft flag to publishing API and don't delete the draft in Manuals Publisher" do
        expect(Services.publishing_api).to receive(:unpublish)
                                             .with(section.uuid,
                                                   type: "redirect",
                                                   alternative_path: redirect,
                                                   discard_drafts: false)
        subject.execute
        expect(SectionEdition.where(section_uuid: section.uuid).pluck(:state)).to eq(["archived", "draft"])
      end
    end
  end

  context "when a dry run is flagged" do
    let(:dry_run) { true }

    it "doesn't action the withdrawal" do
      expect(PublishingAdapter).to_not receive(:unpublish_section)
      subject.execute
    end
  end
end
