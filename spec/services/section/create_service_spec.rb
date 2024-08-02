require "spec_helper"

RSpec.describe Section::CreateService do
  let(:user) { User.gds_editor }
  let(:manual) { Manual.new(title: "manual-title") }
  let(:section_attributes) { double(:section_attributes) }
  let(:new_section) do
    Section.new(uuid: "uuid")
  end

  subject do
    described_class.new(
      user:,
      manual_id: manual.id,
      attributes: section_attributes,
    )
  end

  before do
    allow(Manual)
      .to receive(:find).with(manual.id, user)
      .and_return(manual)
    allow(manual)
      .to receive(:build_section)
      .and_return(new_section)
    allow(PublishingAdapter).to receive(:save_draft)
    allow(PublishingAdapter).to receive(:save_section)
    allow(section_attributes).to receive(:fetch).with(:title).and_return("section-title")
    allow(section_attributes).to receive(:merge).and_return({})
    allow(user).to receive(:name).and_return("Mr Testy")
  end

  context "when the new section is valid" do
    before do
      allow(new_section).to receive(:valid?).and_return(true)
    end

    it "records the user who is creating the section and updates the slug" do
      merged_attributes = double(:merged_attributes)
      allow(section_attributes).to receive(:merge)
        .with({ last_updated_by: user.name, slug: "#{manual.slug}/section-title" })
        .and_return(merged_attributes)

      expect(manual).to receive(:build_section).with(merged_attributes)

      subject.call
    end

    it "marks the manual as draft" do
      expect(manual).to receive(:draft)

      subject.call
    end

    it "saves the draft" do
      expect(manual).to receive(:save!).with(user)

      subject.call
    end

    it "saves the draft manual to the publishing api" do
      expect(PublishingAdapter)
        .to receive(:save_draft).with(manual, include_sections: false)

      subject.call
    end

    it "saves the new section to the publishing api" do
      expect(PublishingAdapter)
        .to receive(:save_section).with(new_section, manual)

      subject.call
    end
  end

  context "when the new section is valid but saving the manual to the publishing api fails" do
    let(:gds_api_exception) { GdsApi::HTTPErrorResponse.new(422) }

    before do
      allow(new_section).to receive(:valid?).and_return(true)
      allow(PublishingAdapter)
        .to receive(:save_draft)
        .and_raise(gds_api_exception)
    end

    it "raises the exception from the gds api" do
      expect { subject.call }.to raise_error(gds_api_exception)
    end

    it "marks the manual as draft" do
      expect(manual).to receive(:draft)

      begin
        subject.call
      rescue StandardError
        gds_api_exception
      end
    end

    it "does not save the manual" do
      expect(manual).to_not receive(:save!).with(user)

      begin
        subject.call
      rescue StandardError
        gds_api_exception
      end
    end

    it "does not save the section to the publishing api" do
      expect(PublishingAdapter)
        .to_not receive(:save_section)

      begin
        subject.call
      rescue StandardError
        gds_api_exception
      end
    end
  end

  context "when the new section is valid but saving the section to the publishing api fails" do
    let(:gds_api_exception) { GdsApi::HTTPErrorResponse.new(422) }

    before do
      allow(new_section).to receive(:valid?).and_return(true)
      allow(PublishingAdapter)
        .to receive(:save_section)
        .and_raise(gds_api_exception)
    end

    it "raises the exception from the gds api" do
      expect { subject.call }.to raise_error(gds_api_exception)
    end

    it "marks the manual as draft" do
      expect(manual).to receive(:draft)

      begin
        subject.call
      rescue StandardError
        gds_api_exception
      end
    end

    it "does not save the manual" do
      expect(manual).to_not receive(:save!).with(user)

      begin
        subject.call
      rescue StandardError
        gds_api_exception
      end
    end

    it "saves the draft manual to the publishing api" do
      expect(PublishingAdapter)
        .to receive(:save_draft).with(manual, include_sections: false)

      begin
        subject.call
      rescue StandardError
        gds_api_exception
      end
    end
  end

  context "when the new section is invalid" do
    before do
      allow(new_section).to receive(:valid?).and_return(false)
    end

    it "does not mark the manual as draft" do
      expect(manual).to_not receive(:draft)

      subject.call
    end

    it "saves the draft" do
      expect(manual).to_not receive(:save!)

      subject.call
    end

    it "saves the draft manual to the publishing api" do
      expect(PublishingAdapter)
        .to_not receive(:save_draft)

      subject.call
    end

    it "saves the new section to the publishing api" do
      expect(PublishingAdapter)
        .to_not receive(:save_section)

      subject.call
    end
  end
end
