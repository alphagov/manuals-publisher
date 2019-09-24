require "spec_helper"

RSpec.describe LinkCheckReport::FindReportableService do
  let(:user) { FactoryBot.create(:user) }
  let(:manual) { double(:manual, id: 1, body: "[link](http://www.example.com)") }

  before do
    allow(Manual).to receive(:find).with(manual.id, user).and_return(manual)
  end

  context "when looking for a manual" do
    subject do
      described_class.new(
        user: user,
        manual_id: manual.id,
      ).call
    end

    it { is_expected.to be(manual) }

    it "should look up a manual" do
      expect(Manual).to receive(:find).with(manual.id, user)
      subject
    end
  end

  context "when looking for a section" do
    let(:manual) { double(:manual, id: 1, body: "[link](http://www.example.com)") }
    let(:section) { double(:section, id: 1, body: "[link](http://www.example.com)") }

    subject do
      described_class.new(
        user: user,
        manual_id: manual.id,
        section_id: section.id,
      ).call
    end

    before do
      allow(Section).to receive(:find).with(manual, section.id).and_return(section)
    end

    it "should look up a manual and a section" do
      expect(Manual).to receive(:find).with(manual.id, user)
      expect(Section).to receive(:find).with(manual, section.id)
      subject
    end
  end
end
