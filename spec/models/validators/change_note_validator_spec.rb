require "spec_helper"

RSpec.describe ChangeNoteValidator do
  subject(:validatable) {
    ChangeNoteValidator.new(section)
  }

  let(:section) {
    double(
      :section,
      change_note_not_required?: change_note_not_required,
      change_note_provided?: change_note_provided,
      errors: section_errors,
      valid?: section_valid,
    )
  }

  let(:change_note_not_required) { true }
  let(:change_note_provided) { false }
  let(:section_errors) {
    double(
      :section_errors_uncast,
      to_hash: section_errors_hash,
    )
  }
  let(:section_errors_hash) { {} }
  let(:section_valid) { false }

  describe "#valid?" do
    context "when the underlying section is not valid" do
      before do
        allow(section).to receive(:valid?).and_return(false)
      end

      it "is not valid" do
        expect(validatable).not_to be_valid
      end
    end

    context "when the section is otherwise valid" do
      before do
        allow(section).to receive(:valid?).and_return(true)
      end

      context "when change note is not required" do
        let(:change_note_not_required) { true }

        it "is valid without a change note" do
          expect(validatable).to be_valid
        end
      end

      context "when change note is required" do
        let(:change_note_not_required) { false }

        context "when the section has a change note" do
          let(:change_note_provided) { true }

          it "is valid" do
            expect(validatable).to be_valid
          end
        end

        context "when the section does not have a change note" do
          let(:change_note_provided) { false }

          it "calls #valid? on the section" do
            validatable.valid?

            expect(section).to have_received(:valid?)
          end

          it "is not valid" do
            expect(validatable).not_to be_valid
          end
        end
      end
    end
  end

  describe "#errors" do
    context "when a change note is missing" do
      let(:change_note_provided) { false }
      let(:change_note_not_required) { false }

      before do
        validatable.valid?
      end

      it "returns an error string for that field" do
        expect(validatable.errors.fetch(:change_note))
          .to eq(["You must provide a change note or indicate minor update"])
      end

      context "when the underlying section has errors" do
        let(:section_errors_hash) {
          {
            another_field: ["is not valid"],
          }
        }

        it "combines all errors" do
          expect(validatable.errors.fetch(:another_field))
            .to eq(["is not valid"])
        end
      end
    end

    context "transitioning from invalid to valid" do
      let(:change_note_provided) { false }
      let(:change_note_not_required) { false }
      let(:section_valid) { true }

      before do
        validatable.valid?
        allow(section).to receive(:change_note_provided?).and_return(true)
        validatable.valid?
      end

      it "resets the errors, returning an empty hash" do
        expect(validatable.errors).to eq({})
      end
    end
  end
end
