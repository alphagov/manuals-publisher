RSpec.describe Section::UpdateService do
  let(:user) { User.gds_editor }
  let(:manual) { Manual.new(title: "manual-title") }
  let(:section_uuid) { "section-uuid" }
  let(:section) do
    Section.new(uuid: section_uuid)
  end
  let(:section_attributes) { { title: "updated-title" } }

  subject do
    described_class.new(
      user:,
      manual_id: manual.id,
      section_uuid:,
      attributes: section_attributes,
    )
  end

  before do
    allow(manual).to receive(:sections).and_return([section])
    allow(manual).to receive(:save!)
    allow(Manual)
      .to receive(:find).with(manual.id, user)
      .and_return(manual)
    allow(Publishing::DraftAdapter).to receive(:save_draft_for_manual_and_sections)
    allow(Publishing::DraftAdapter).to receive(:save_draft_for_section)
  end

  context "when the new section is valid" do
    before do
      allow(section).to receive(:valid?).and_return(true)
    end

    it "records the user who is updating the section and updates the slug" do
      merged_attributes = double(:merged_attributes)
      allow(section_attributes).to receive(:merge)
        .with({ last_updated_by: user.name, slug: "#{manual.slug}/updated-title" })
        .and_return(merged_attributes)

      expect(section).to receive(:assign_attributes).with(merged_attributes)

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
      expect(Publishing::DraftAdapter)
        .to receive(:save_draft_for_manual_and_sections).with(manual, include_sections: false)

      subject.call
    end

    it "saves the new section to the publishing api" do
      expect(Publishing::DraftAdapter)
        .to receive(:save_draft_for_section).with(section, manual)

      subject.call
    end
  end

  context "when the new section is valid but saving the manual to the publishing api fails" do
    let(:gds_api_exception) { GdsApi::HTTPErrorResponse.new(422) }

    before do
      allow(section).to receive(:valid?).and_return(true)
      allow(Publishing::DraftAdapter)
        .to receive(:save_draft_for_manual_and_sections).and_raise(gds_api_exception)
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
      expect(Publishing::DraftAdapter)
        .to_not receive(:save_draft_for_section).with(section, manual)

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
      allow(Publishing::DraftAdapter)
        .to receive(:save_draft_for_section).and_raise(gds_api_exception)
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
      expect(Publishing::DraftAdapter)
        .to receive(:save_draft_for_manual_and_sections).with(manual, include_sections: false)

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
      expect(Publishing::DraftAdapter)
        .to_not receive(:save_draft_for_manual_and_sections)

      subject.call
    end

    it "saves the new section to the publishing api" do
      expect(Publishing::DraftAdapter)
        .to_not receive(:save_draft_for_section)

      subject.call
    end
  end
end
