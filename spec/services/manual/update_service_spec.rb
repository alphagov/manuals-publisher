require "spec_helper"

RSpec.describe Manual::UpdateService do
  let(:user) { double(:user) }
  let(:manual) { instance_double(Manual, id: "1", draft: nil, assign_attributes: nil, save!: nil, organisation_slug: "org") }

  subject do
    described_class.new(
      user:,
      manual_id: "1",
      attributes: {},
    )
  end

  before do
    allow(Manual).to receive(:find).and_return(manual)
  end

  it "does not allow saving of an invalid manual" do
    allow(manual).to receive(:valid?).and_return(false)
    expect(PublishingAdapter).not_to receive(:save_draft)

    subject.call

    expect(manual).not_to have_received(:save!)
  end

  it "allows saving of a valid manual" do
    allow(manual).to receive(:valid?).and_return(true)
    expect(PublishingAdapter).to receive(:save_draft)

    subject.call

    expect(manual).to have_received(:save!)
  end
end
