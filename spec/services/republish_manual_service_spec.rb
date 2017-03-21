require "spec_helper"
require "republish_manual_service"
require "versioned_manual_repository"

RSpec.describe RepublishManualService do
  let(:manual_id) { double(:manual_id) }
  let(:published_listener) { double(:listener) }
  let(:published_listeners) { [published_listener] }
  let(:draft_listener) { double(:listener) }
  let(:draft_listeners) { [draft_listener] }
  let(:registry) { double(:registry, update: draft_listeners, republication: published_listeners) }
  let(:published_manual_version) { double(:manual) }
  let(:draft_manual_version) { double(:manual) }

  subject {
    described_class.new(
      manual_id: manual_id,
    )
  }

  before do
    allow(draft_listener).to receive(:call)
    allow(published_listener).to receive(:call)
    allow(ManualObserversRegistry).to receive(:new).and_return(registry)
  end

  context "(for a published manual)" do
    before do
      allow(VersionedManualRepository).to receive(:get_manual)
        .with(manual_id)
        .and_return(
          published: published_manual_version,
          draft: nil
        )
    end

    it "tells the published listeners to republish the published version of the manual" do
      subject.call
      expect(published_listener).to have_received(:call).with(published_manual_version, :republish)
    end

    it "tells the draft listeners nothing" do
      subject.call
      expect(draft_listener).not_to have_received(:call)
    end
  end

  context "(for a draft manual)" do
    before do
      allow(VersionedManualRepository).to receive(:get_manual)
        .with(manual_id)
        .and_return(
          published: nil,
          draft: draft_manual_version
        )
    end

    it "tells the published listeners nothing" do
      subject.call
      expect(published_listener).not_to have_received(:call)
    end

    it "tells the draft listeners to republish the draft version of the manual" do
      subject.call
      expect(draft_listener).to have_received(:call).with(draft_manual_version, :republish)
    end
  end

  context "(for a published manual with a new draft waiting)" do
    before do
      allow(VersionedManualRepository).to receive(:get_manual)
        .with(manual_id)
        .and_return(
          published: published_manual_version,
          draft: draft_manual_version
        )
    end

    it "tells the published listeners to republish the published version of the manual" do
      subject.call
      expect(published_listener).to have_received(:call).with(published_manual_version, :republish)
    end

    it "tells the draft listeners to republish the draft version of the manual" do
      subject.call
      expect(draft_listener).to have_received(:call).with(draft_manual_version, :republish)
    end
  end

  context "(for a manual that doesn't exist)" do
    before do
      allow(VersionedManualRepository).to receive(:get_manual)
        .with(manual_id)
        .and_raise(VersionedManualRepository::NotFoundError.new("uh-oh!"))
    end

    it "raises an exception" do
      expect {
        subject.call
      }.to raise_error(RepublishManualService::ManualNotFoundError)
    end

    it "tells none of the listeners to do anything" do
      begin; subject.call; rescue(RepublishManualService::ManualNotFoundError); end
      expect(published_listener).not_to have_received(:call)
      expect(draft_listener).not_to have_received(:call)
    end
  end

  context "(for a manual that exists, but is neither published, nor draft)" do
    before do
      allow(VersionedManualRepository).to receive(:get_manual)
        .with(manual_id)
        .and_return(
          published: nil,
          draft: nil
        )
    end

    it "tells none of the listeners to do anything" do
      subject.call
      expect(published_listener).not_to have_received(:call)
      expect(draft_listener).not_to have_received(:call)
    end
  end
end
