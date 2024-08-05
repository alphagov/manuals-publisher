RSpec.describe Manual::CreateService do
  let(:user) { double(:user) }
  let(:manual) { double(:manual, valid?: nil, save!: nil, organisation_slug: "org") }

  subject do
    described_class.new(
      user:,
      attributes: {},
    )
  end

  before do
    allow(Manual).to receive(:new).and_return(manual)
  end

  context "when the manual is valid" do
    before do
      allow(manual).to receive(:valid?).and_return(true)
    end

    it "saves the manual" do
      expect(manual).to receive(:save!)
      expect(Publishing::DraftAdapter).to receive(:save_draft_for_manual_and_sections).with(manual)
      subject.call
    end
  end

  context "when the manual is valid but saving it to the Publishing API fails" do
    let(:gds_api_exception) { GdsApi::HTTPErrorResponse.new(422) }

    before do
      allow(manual).to receive(:valid?).and_return(true)
      allow(Publishing::DraftAdapter)
        .to receive(:save_draft_for_manual_and_sections).and_raise(gds_api_exception)
    end

    it "raises the exception and does not save manual" do
      expect(manual).to_not receive(:save!)
      expect { subject.call }.to raise_error(gds_api_exception)
    end
  end

  context "when the manual is not valid" do
    before do
      allow(manual).to receive(:valid?).and_return(false)
    end

    it "does not save the manual" do
      expect(manual).to_not receive(:save!)
      expect(Publishing::DraftAdapter).to_not receive(:save_draft_for_manual_and_sections).with(manual)
      subject.call
    end
  end
end
