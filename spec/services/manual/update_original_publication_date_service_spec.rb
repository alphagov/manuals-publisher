RSpec.describe Manual::UpdateOriginalPublicationDateService do
  let(:manual_id) { double(:manual_id) }
  let(:manual) { double(:manual, id: manual_id, sections:) }
  let(:section1) { double(:section, assign_attributes: nil) }
  let(:section2) { double(:section, assign_attributes: nil) }
  let(:sections) { [section1, section2] }
  let(:originally_published_at) { 10.years.ago }
  let(:user) { double(:user) }

  subject do
    described_class.new(
      user:,
      manual_id:,
      attributes: {
        originally_published_at:,
        use_originally_published_at_for_public_timestamp: "1",
        title: "hats",
      },
    )
  end

  before do
    allow(Manual).to receive(:find).and_return(manual)
    allow(manual).to receive(:draft)
    allow(manual).to receive(:assign_attributes)
    allow(manual).to receive(:save!)
    allow(PublishingAdapter).to receive(:save_draft)
  end

  it "updates the manual with only the originally_published_at and use_originally_published_at_for_public_timestamp attribtues" do
    subject.call
    expect(manual).to have_received(:assign_attributes)
      .with(
        originally_published_at:,
        use_originally_published_at_for_public_timestamp: "1",
      )
  end

  it "forces all the manuals sections to require an export with a nil change note" do
    subject.call

    expect(section1).to have_received(:assign_attributes).with(change_note: nil)
    expect(section2).to have_received(:assign_attributes).with(change_note: nil)
  end

  it "persists the manual after it has been updated" do
    subject.call

    expect(manual).to have_received(:assign_attributes).ordered
    expect(manual).to have_received(:save!).with(user).ordered
  end

  it "tells each listener about the event after the manual has been stored" do
    subject.call

    expect(manual).to have_received(:save!).with(user).ordered
    expect(PublishingAdapter).to have_received(:save_draft).with(manual).ordered
  end
end
