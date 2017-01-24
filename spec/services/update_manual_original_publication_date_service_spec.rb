require "spec_helper"
require "update_manual_original_publication_date_service"

RSpec.describe UpdateManualOriginalPublicationDateService do

  let(:manual_id) { double(:manual_id) }
  let(:manual_repository) { double(:manual_repository) }
  let(:manual) { double(:manual, id: manual_id, documents: documents) }
  let(:document_1) { double(:document, update: nil) }
  let(:document_2) { double(:document, update: nil) }
  let(:documents) { [document_1, document_2] }
  let(:originally_published_at) { 10.years.ago }
  let(:listener_1) { double(:listener, call: nil) }
  let(:listener_2) { double(:listener, call: nil) }
  let(:listeners) { [listener_1, listener_2] }

  subject {
    described_class.new(
      manual_id: manual_id,
      manual_repository: manual_repository,
      attributes: {
        originally_published_at: originally_published_at,
        use_originally_published_at_for_public_timestamp: "1",
        title: "hats",
      },
      listeners: listeners
    )
  }

  before do
    allow(manual_repository).to receive(:fetch) { manual }
    allow(manual_repository).to receive(:store)
    allow(manual).to receive(:draft)
    allow(manual).to receive(:update)
  end

  it "updates the manual with only the originally_published_at and use_originally_published_at_for_public_timestamp attribtues" do
    subject.call
    expect(manual).to have_received(:update)
      .with(
        originally_published_at: originally_published_at,
        use_originally_published_at_for_public_timestamp: "1"
      )
  end

  it "forces all the manuals documents to require an export with an empty update message" do
    subject.call

    expect(document_1).to have_received(:update).with({})
    expect(document_2).to have_received(:update).with({})
  end

  it "persists the manual after it has been updated" do
    subject.call

    expect(manual).to have_received(:update).ordered
    expect(manual_repository).to have_received(:store).with(manual).ordered
  end

  it "tells each listener about the event after the manual has been stored" do
    subject.call

    expect(manual_repository).to have_received(:store).with(manual).ordered
    expect(listener_1).to have_received(:call).with(manual).ordered
    expect(listener_2).to have_received(:call).with(manual).ordered
  end
end
