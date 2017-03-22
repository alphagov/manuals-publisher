require "spec_helper"

RSpec.describe ManualUpdateType do
  let(:manual) { double(:manual) }
  subject { described_class.for(manual) }

  describe "for a manual that has never been published" do
    before { allow(manual).to receive(:has_ever_been_published?).and_return false }

    it "is 'major'" do
      expect(subject).to eql "major"
    end
  end

  describe "for a manual that has been published before" do
    before { allow(manual).to receive(:has_ever_been_published?).and_return true }

    context "and has no documents" do
      before { allow(manual).to receive(:sections).and_return [] }

      it "is 'minor'" do
        expect(subject).to eql "minor"
      end
    end

    context "and has sections" do
      let(:section_1) { double(:section) }
      let(:section_2) { double(:section) }
      let(:section_3) { double(:section) }
      before { allow(manual).to receive(:sections).and_return [section_1, section_2, section_3] }

      context "none of which need exporting" do
        before do
          allow(section_1).to receive(:needs_exporting?).and_return false
          allow(section_2).to receive(:needs_exporting?).and_return false
          allow(section_3).to receive(:needs_exporting?).and_return false
        end

        it "is 'minor'" do
          expect(subject).to eql "minor"
        end
      end

      context "some of which need exporting" do
        before do
          allow(section_1).to receive(:needs_exporting?).and_return true
          allow(section_2).to receive(:needs_exporting?).and_return true
          allow(section_3).to receive(:needs_exporting?).and_return true
        end

        it "is 'minor' when all documents are minor updates that have been published before" do
          allow(section_1).to receive(:minor_update?).and_return true
          allow(section_2).to receive(:minor_update?).and_return true
          allow(section_3).to receive(:minor_update?).and_return true
          allow(section_1).to receive(:has_ever_been_published?).and_return true
          allow(section_2).to receive(:has_ever_been_published?).and_return true
          allow(section_3).to receive(:has_ever_been_published?).and_return true

          expect(subject).to eql "minor"
        end

        it "is 'major' when at least one document is a minor update that has never been published before" do
          allow(section_1).to receive(:minor_update?).and_return true
          allow(section_2).to receive(:minor_update?).and_return true
          allow(section_3).to receive(:minor_update?).and_return true
          allow(section_1).to receive(:has_ever_been_published?).and_return true
          allow(section_2).to receive(:has_ever_been_published?).and_return true
          allow(section_3).to receive(:has_ever_been_published?).and_return false

          expect(subject).to eql "major"
        end

        it "is 'major' when at least one documents is a major update" do
          allow(section_1).to receive(:minor_update?).and_return false
          allow(section_2).to receive(:minor_update?).and_return true
          allow(section_3).to receive(:minor_update?).and_return true
          allow(section_1).to receive(:has_ever_been_published?).and_return true
          allow(section_2).to receive(:has_ever_been_published?).and_return true
          allow(section_3).to receive(:has_ever_been_published?).and_return true

          expect(subject).to eql "major"
        end
      end
    end
  end
end
