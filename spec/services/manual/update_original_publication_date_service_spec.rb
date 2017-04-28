require "spec_helper"

RSpec.describe Manual::UpdateOriginalPublicationDateService do
  let(:manual_id) { double(:manual_id) }
  let(:manual) { double(:manual, id: manual_id, sections: sections) }
  let(:section_1) { double(:section, update: nil) }
  let(:section_2) { double(:section, update: nil) }
  let(:sections) { [section_1, section_2] }
  let(:originally_published_at) { 10.years.ago }
  let(:publishing_api_draft_exporter) { double(:publishing_api_draft_exporter) }
  let(:context) { double(:context, current_user: user) }
  let(:user) { double(:user) }

  subject {
    described_class.new(
      manual_id: manual_id,
      attributes: {
        originally_published_at: originally_published_at,
        use_originally_published_at_for_public_timestamp: "1",
        title: "hats",
      },
      context: context
    )
  }

  before do
    allow(Manual).to receive(:find).and_return(manual)
    allow(manual).to receive(:draft)
    allow(manual).to receive(:update)
    allow(manual).to receive(:save)
    allow(PublishingApiDraftManualWithSectionsExporter).to receive(:new) { publishing_api_draft_exporter }
    allow(publishing_api_draft_exporter).to receive(:call)
  end

  it "updates the manual with only the originally_published_at and use_originally_published_at_for_public_timestamp attribtues" do
    subject.call
    expect(manual).to have_received(:update)
      .with(
        originally_published_at: originally_published_at,
        use_originally_published_at_for_public_timestamp: "1"
      )
  end

  it "forces all the manuals sections to require an export with a nil change note" do
    subject.call

    expect(section_1).to have_received(:update).with(change_note: nil)
    expect(section_2).to have_received(:update).with(change_note: nil)
  end

  it "persists the manual after it has been updated" do
    subject.call

    expect(manual).to have_received(:update).ordered
    expect(manual).to have_received(:save).with(user).ordered
  end

  it "tells each listener about the event after the manual has been stored" do
    subject.call

    expect(manual).to have_received(:save).with(user).ordered
    expect(publishing_api_draft_exporter).to have_received(:call).with(manual).ordered
  end
end
