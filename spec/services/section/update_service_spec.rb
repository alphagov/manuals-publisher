require "spec_helper"

RSpec.describe Section::UpdateService do
  let(:user) { User.gds_editor }
  let(:manual) { Manual.new(title: "manual-title") }
  let(:section_uuid) { "section-uuid" }
  let(:publishing_api_adapter) { double(:publishing_api) }
  let(:section) do
    Section.new(manual: manual, uuid: section_uuid)
  end

  subject do
    described_class.new(
      user: user,
      manual_id: manual.id,
      section_uuid: section_uuid,
      attributes: {},
    )
  end

  before do
    allow(manual).to receive(:sections).and_return([section])
    allow(manual).to receive(:save!)
    allow(Manual)
      .to receive(:find).with(manual.id, user)
      .and_return(manual)
    allow(Adapters).to receive(:publishing)
      .and_return(publishing_api_adapter)
    allow(publishing_api_adapter).to receive(:save_draft)
    allow(publishing_api_adapter).to receive(:save_section)
  end

  context "when the new section is valid" do
    before do
      allow(section).to receive(:valid?).and_return(true)
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
      expect(publishing_api_adapter)
        .to receive(:save_draft).with(manual, include_sections: false)

      subject.call
    end

    it "saves the new section to the publishing api" do
      expect(publishing_api_adapter)
        .to receive(:save_section).with(section, manual)

      subject.call
    end
  end

  context "when the new section is valid but saving the manual to the publishing api fails" do
    let(:gds_api_exception) { GdsApi::HTTPErrorResponse.new(422) }

    before do
      allow(section).to receive(:valid?).and_return(true)
      allow(publishing_api_adapter)
        .to receive(:save_draft).and_raise(gds_api_exception)
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

    it "does not save the draft" do
      expect(manual).to_not receive(:save!).with(user)

      begin
        subject.call
      rescue StandardError
        gds_api_exception
      end
    end

    it "does not save the section to the publishing api" do
      expect(publishing_api_adapter)
        .to_not receive(:save_section).with(section, manual)

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
      allow(section).to receive(:valid?).and_return(true)
      allow(publishing_api_adapter)
        .to receive(:save_section).and_raise(gds_api_exception)
    end

    it "raises the exception from the gds api" do
      expect { subject.call }.to raise_error(gds_api_exception)
    end

    it "does marks the manual as draft" do
      expect(manual).to receive(:draft)

      begin
        subject.call
      rescue StandardError
        gds_api_exception
      end
    end

    it "does not save the draft" do
      expect(manual).to_not receive(:save!).with(user)

      begin
        subject.call
      rescue StandardError
        gds_api_exception
      end
    end

    it "saves the draft manual to the publishing api" do
      expect(publishing_api_adapter)
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
      allow(section).to receive(:valid?).and_return(false)
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
      expect(publishing_api_adapter)
        .to_not receive(:save_draft)

      subject.call
    end

    it "saves the new section to the publishing api" do
      expect(publishing_api_adapter)
        .to_not receive(:save_section)

      subject.call
    end
  end
end
