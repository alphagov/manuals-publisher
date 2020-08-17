require "spec_helper"

RSpec.describe Section::RemoveService do
  let(:section_uuid) { "123" }

  let(:manual) do
    double(
      draft: nil,
      remove_section: nil,
      find_section: section,
    )
  end

  let(:user) { double(:user) }

  let(:service) do
    described_class.new(
      user: user,
      manual_id: "ABC",
      section_uuid: section_uuid,
      attributes: change_note_params,
    )
  end
  let(:publishing_adapter) { spy(PublishingAdapter) }

  before do
    allow(Manual).to receive(:find).and_return(manual)
    allow(manual).to receive(:save!)
    allow(Adapters).to receive(:publishing).and_return(publishing_adapter)
  end

  context "with a section id that doesn't belong to the manual" do
    let(:section) do
      double(uuid: section_uuid)
    end
    let(:manual) do
      double(
        draft: nil,
        sections: [],
        remove_section: nil,
        find_section: nil,
      )
    end
    let(:change_note_params) do
      {
        minor_update: "0",
        change_note: "Make a change",
      }
    end

    it "raises a SectionNotFoundError" do
      expect {
        service.call
      }.to raise_error(described_class::SectionNotFoundError, section_uuid)
    end

    context "when SectionNotFoundError is raised" do
      before do
        expect { service.call }.to raise_error(described_class::SectionNotFoundError)
      end

      it "does not mark the manual as a draft" do
        expect(manual).not_to have_received(:draft)
      end

      it "does not export a manual" do
        expect(publishing_adapter).not_to have_received(:save_draft)
      end

      it "does not discard a section" do
        expect(publishing_adapter).not_to have_received(:discard_section)
      end
    end
  end

  context "with invalid change_note params" do
    let(:section) do
      double(
        uuid: section_uuid,
        published?: true,
        assign_attributes: nil,
        valid?: false,
      )
    end
    let(:change_note_params) do
      {
        minor_update: "1",
        change_note: "",
      }
    end

    before do
      service.call
    end

    it "tries to save the change note to the section" do
      expect(section).to have_received(:assign_attributes).with(change_note_params)
    end

    it "does not removes the section" do
      expect(manual).not_to have_received(:remove_section).with(section.uuid)
    end

    it "does not mark the manual as a draft" do
      expect(manual).not_to have_received(:draft)
    end

    it "does not persists the manual" do
      expect(manual).not_to have_received(:save!).with(user)
    end

    it "does not export a manual" do
      expect(publishing_adapter).not_to have_received(:save_draft)
    end

    it "does not discard a section" do
      expect(publishing_adapter).not_to have_received(:discard_section)
    end
  end

  context "with valid change_note params" do
    let(:change_note_params) do
      {
        minor_update: "0",
        change_note: "Make a change",
      }
    end

    context "with a section that's previously been published" do
      let(:section) do
        double(
          uuid: section_uuid,
          published?: true,
          assign_attributes: nil,
          valid?: true,
        )
      end

      before do
        service.call
      end

      it "saves the change note to the section" do
        expect(section).to have_received(:assign_attributes).with(change_note_params)
      end

      it "removes the section" do
        expect(manual).to have_received(:remove_section).with(section.uuid)
      end

      it "marks the manual as a draft" do
        expect(manual).to have_received(:draft)
      end

      it "persists the manual" do
        expect(manual).to have_received(:save!).with(user)
      end

      it "exports a manual" do
        expect(publishing_adapter).to have_received(:save_draft).with(manual, include_sections: false)
      end

      it "discards a section" do
        expect(publishing_adapter).to have_received(:discard_section).with(section)
      end
    end

    context "with a section that's never been published" do
      let(:section) do
        double(
          uuid: section_uuid,
          published?: false,
          assign_attributes: nil,
          valid?: true,
        )
      end

      before do
        service.call
      end

      it "saves the change note to the section" do
        expect(section).to have_received(:assign_attributes).with(minor_update: "0", change_note: "Make a change")
      end

      it "removes the section" do
        expect(manual).to have_received(:remove_section).with(section_uuid)
      end

      it "marks the manual as a draft" do
        # NOTE - this isn't neccesary really, but we do it to be consistent
        expect(manual).to have_received(:draft)
      end

      it "persists the manual" do
        expect(manual).to have_received(:save!).with(user)
      end

      it "exports a manual" do
        expect(publishing_adapter).to have_received(:save_draft).with(manual, include_sections: false)
      end

      it "discards a section" do
        expect(publishing_adapter).to have_received(:discard_section).with(section)
      end
    end

    context "with extra section params" do
      let(:section) do
        double(
          uuid: section_uuid,
          published?: true,
          assign_attributes: nil,
          valid?: true,
        )
      end
      let(:change_note_params) do
        {
          minor_update: "0",
          change_note: "Make a change",
          title: "Sneakily try to change this",
        }
      end

      before do
        service.call
      end

      it "only saves the change note params to the section ignoring others" do
        expect(section).to have_received(:assign_attributes).with(change_note_params.slice(:change_note, :minor_update))
      end
    end
  end
end
