require "spec_helper"

RSpec.describe Manual::CreateService do
  let(:user) { double(:user) }
  let(:manual) { double(:manual, valid?: nil, save!: nil) }
  let(:publishing_api_adapter) { double(:publishing_api_adapter, save_draft: nil) }

  subject do
    described_class.new(
      user: user,
      attributes: {},
    )
  end

  before do
    allow(Manual).to receive(:new).and_return(manual)
    allow(Adapters)
      .to receive(:publishing).and_return(publishing_api_adapter)
  end

  context "when the manual is valid" do
    before do
      allow(manual).to receive(:valid?).and_return(true)
    end

    it "saves the manual" do
      expect(manual).to receive(:save!)
      subject.call
    end

    it "saves the manual to the Publishing API" do
      expect(publishing_api_adapter).to receive(:save_draft).with(manual)
      subject.call
    end
  end

  context "when the manual is valid but saving it to the Publishing API fails" do
    let(:gds_api_exception) { GdsApi::HTTPErrorResponse.new(422) }

    before do
      allow(manual).to receive(:valid?).and_return(true)
      allow(publishing_api_adapter)
        .to receive(:save_draft).and_raise(gds_api_exception)
    end

    it "raises the exception" do
      expect { subject.call }.to raise_error(gds_api_exception)
    end

    it "does not save the manual" do
      expect(manual).to_not receive(:save!)
      begin
        subject.call
      rescue StandardError
        gds_api_exception
      end
    end
  end

  context "when the manual is not valid" do
    before do
      allow(manual).to receive(:valid?).and_return(false)
    end

    it "does not save the manual" do
      expect(manual).to_not receive(:save!)
      subject.call
    end

    it "does not save the manual to the Publishing API" do
      expect(publishing_api_adapter).to_not receive(:save_draft).with(manual)
      subject.call
    end
  end
end
