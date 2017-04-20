require "spec_helper"

RSpec.describe Section::RemoveService do
  let(:section_id) { "123" }

  let(:manual) {
    double(
      draft: nil,
      sections: [
        section,
      ],
      remove_section: nil,
    )
  }

  let(:user) { double(:user) }

  let(:service_context) {
    double(
      params: {
        "id" => section_id,
        "manual_id" => "ABC",
        "section" => change_note_params
      },
      current_user: user
    )
  }

  let(:service) {
    described_class.new(
      context: service_context,
    )
  }
  let(:discarder) { spy(PublishingApiDraftSectionDiscarder) }
  let(:exporter) { spy(PublishingApiDraftManualExporter) }

  before do
    allow(Manual).to receive(:find).and_return(manual)
    allow(manual).to receive(:save)
    allow(PublishingApiDraftManualExporter).to receive(:new).and_return(exporter)
    allow(PublishingApiDraftSectionDiscarder).to receive(:new).and_return(discarder)
  end

  context "with a section id that doesn't belong to the manual" do
    let(:section) {
      double(id: section_id)
    }
    let(:manual) {
      double(
        draft: nil,
        sections: [],
        remove_section: nil,
      )
    }
    let(:change_note_params) do
      {
        "minor_update" => "0",
        "change_note" => "Make a change"
      }
    end

    it "raises a SectionNotFoundError" do
      expect {
        service.call
      }.to raise_error(described_class::SectionNotFoundError, section_id)
    end

    context "when SectionNotFoundError is raised" do
      before do
        ignoring(described_class::SectionNotFoundError) { service.call }
      end

      it "does not mark the manual as a draft" do
        expect(manual).not_to have_received(:draft)
      end

      it "does not export a manual" do
        expect(exporter).not_to have_received(:call)
      end

      it "does not discard a section" do
        expect(discarder).not_to have_received(:call)
      end

      def ignoring(exception_class)
        yield
      rescue exception_class
      end
    end
  end

  context "with invalid change_note params" do
    let(:section) {
      double(
        id: section_id,
        published?: true,
        update: nil,
        valid?: false,
      )
    }
    let(:change_note_params) do
      {
        "minor_update" => "1",
        "change_note" => "",
      }
    end

    before do
      service.call
    end

    it "tries to save the change note to the section" do
      expect(section).to have_received(:update).with(change_note_params)
    end

    it "does not removes the section" do
      expect(manual).not_to have_received(:remove_section).with(section.id)
    end

    it "does not mark the manual as a draft" do
      expect(manual).not_to have_received(:draft)
    end

    it "does not persists the manual" do
      expect(manual).not_to have_received(:save).with(user)
    end

    it "does not export a manual" do
      expect(exporter).not_to have_received(:call)
    end

    it "does not discard a section" do
      expect(discarder).not_to have_received(:call)
    end
  end

  context "with valid change_note params" do
    let(:change_note_params) do
      {
        "minor_update" => "0",
        "change_note" => "Make a change"
      }
    end

    context "with a section that's previously been published" do
      let(:section) {
        double(
          id: section_id,
          published?: true,
          update: nil,
          valid?: true,
        )
      }

      before do
        service.call
      end

      it "saves the change note to the section" do
        expect(section).to have_received(:update).with(change_note_params)
      end

      it "removes the section" do
        expect(manual).to have_received(:remove_section).with(section.id)
      end

      it "marks the manual as a draft" do
        expect(manual).to have_received(:draft)
      end

      it "persists the manual" do
        expect(manual).to have_received(:save).with(user)
      end

      it "exports a manual" do
        expect(exporter).to have_received(:call).with(manual)
      end

      it "discards a section" do
        expect(discarder).to have_received(:call).with(section, manual)
      end
    end

    context "with a section that's never been published" do
      let(:section) {
        double(
          id: section_id,
          published?: false,
          update: nil,
          valid?: true,
        )
      }

      before do
        service.call
      end

      it "saves the change note to the section" do
        expect(section).to have_received(:update).with("minor_update" => "0", "change_note" => "Make a change")
      end

      it "removes the section" do
        expect(manual).to have_received(:remove_section).with(section_id)
      end

      it "marks the manual as a draft" do
        # NOTE - this isn't neccesary really, but we do it to be consistent
        expect(manual).to have_received(:draft)
      end

      it "persists the manual" do
        expect(manual).to have_received(:save).with(user)
      end

      it "exports a manual" do
        expect(exporter).to have_received(:call).with(manual)
      end

      it "discards a section" do
        expect(discarder).to have_received(:call).with(section, manual)
      end
    end

    context "with extra section params" do
      let(:section) {
        double(
          id: section_id,
          published?: true,
          update: nil,
          valid?: true,
        )
      }
      let(:change_note_params) do
        {
          "minor_update" => "0",
          "change_note" => "Make a change",
          "title" => "Sneakily try to change this"
        }
      end

      before do
        service.call
      end

      it "only saves the change note params to the section ignoring others" do
        expect(section).to have_received(:update).with(change_note_params.slice("change_note", "minor_update"))
      end
    end
  end
end
