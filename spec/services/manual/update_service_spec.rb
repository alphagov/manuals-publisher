require "spec_helper"

RSpec.describe Manual::UpdateService do
  let(:user) { double(:user) }
  let(:manual) { instance_double(Manual, id: "1", draft: nil, assign_attributes: nil, save!: nil) }
  let(:publishing_api_adapter) { double(:publishing_api_adapter, save_draft: nil) }

  subject do
    described_class.new(
      user:,
      manual_id: "1",
      attributes: {},
    )
  end

  before do
    allow(Manual).to receive(:find).and_return(manual)
    allow(Adapters)
      .to receive(:publishing).and_return(publishing_api_adapter)
  end

  it "does not allow saving of an invalid manual" do
    allow(manual).to receive(:valid?).and_return(false)

    subject.call

    expect(manual).not_to have_received(:save!)
    expect(publishing_api_adapter).not_to have_received(:save_draft)
  end

  it "allows saving of a valid manual" do
    allow(manual).to receive(:valid?).and_return(true)

    subject.call

    expect(manual).to have_received(:save!)
    expect(publishing_api_adapter).to have_received(:save_draft)
  end
end
