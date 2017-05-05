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

    context "when all sections are minor" do
      before do
        allow(manual).to receive(:all_sections_are_minor?).and_return(true)
      end

      it "is 'minor'" do
        expect(subject).to eql "minor"
      end
    end

    context "when all sections are not minor" do
      before do
        allow(manual).to receive(:all_sections_are_minor?).and_return(false)
      end

      it "is 'major'" do
        expect(subject).to eql "major"
      end
    end
  end
end
