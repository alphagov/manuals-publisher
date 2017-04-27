require "spec_helper"

RSpec.describe Manual::RepublishService do
  let(:manual_id) { double(:manual_id) }
  let(:published_manual_version) { double(:manual) }
  let(:draft_manual_version) { double(:manual) }
  let(:publishing_api_draft_exporter) { double(:publishing_api_draft_exporter) }
  let(:publishing_api_publisher) { double(:publishing_api_publisher) }
  let(:rummager_exporter) { double(:rummager_exporter) }
  let(:manual) { double(:manual) }
  let(:user) { double(:user) }
  let(:context) { double(:context, current_user: user) }

  subject {
    described_class.new(
      manual_id: manual_id,
      context: context,
    )
  }

  before do
    allow(PublishingApiDraftManualWithSectionsExporter).to receive(:new) { publishing_api_draft_exporter }
    allow(PublishingApiManualWithSectionsPublisher).to receive(:new) { publishing_api_publisher }
    allow(RummagerManualWithSectionsExporter).to receive(:new) { rummager_exporter }
    allow(publishing_api_draft_exporter).to receive(:call)
    allow(publishing_api_publisher).to receive(:call)
    allow(rummager_exporter).to receive(:call)
    allow(Manual).to receive(:find).with(manual_id, user) { manual }
  end

  context "(for a published manual)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: published_manual_version,
          draft: nil
        )
    end

    it "calls the publishing api draft exporter" do
      subject.call
      expect(publishing_api_draft_exporter).to have_received(:call).with(published_manual_version, :republish)
    end

    it "calls the new publishing api publisher" do
      subject.call
      expect(publishing_api_publisher).to have_received(:call).with(published_manual_version, :republish)
    end

    it "calls the rummager exporter" do
      subject.call
      expect(rummager_exporter).to have_received(:call).with(published_manual_version)
    end

    it "tells the draft listeners nothing" do
      subject.call
      expect(publishing_api_draft_exporter).not_to have_received(:call).with(draft_manual_version, :republish)
    end
  end

  context "(for a draft manual)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: nil,
          draft: draft_manual_version
        )
    end

    it "tells the published listeners nothing" do
      subject.call
      expect(publishing_api_publisher).not_to have_received(:call)
      expect(publishing_api_draft_exporter).not_to have_received(:call).with(published_manual_version, :republish)
      expect(rummager_exporter).not_to have_received(:call)
    end

    it "tells the draft listeners to republish the draft version of the manual" do
      subject.call
      expect(publishing_api_draft_exporter).to have_received(:call).with(draft_manual_version, :republish)
    end
  end

  context "(for a published manual with a new draft waiting)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: published_manual_version,
          draft: draft_manual_version
        )
    end

    it "calls the publishing api draft exporter" do
      subject.call
      expect(publishing_api_draft_exporter).to have_received(:call).with(published_manual_version, :republish)
    end

    it "calls the new publishing api publisher" do
      subject.call
      expect(publishing_api_publisher).to have_received(:call).with(published_manual_version, :republish)
    end

    it "calls the rummager exporter" do
      subject.call
      expect(rummager_exporter).to have_received(:call).with(published_manual_version)
    end

    it "tells the draft listeners to republish the draft version of the manual" do
      subject.call
      expect(publishing_api_draft_exporter).to have_received(:call).with(draft_manual_version, :republish)
    end
  end

  context "(for a manual that doesn't exist)" do
    let(:arbitrary_exception) { Class.new(StandardError) }

    before do
      allow(manual).to receive(:current_versions)
        .and_raise(arbitrary_exception)
    end

    it "tells none of the listeners to do anything" do
      begin; subject.call; rescue(arbitrary_exception); end
      expect(publishing_api_draft_exporter).not_to have_received(:call)
      expect(publishing_api_publisher).not_to have_received(:call)
      expect(rummager_exporter).not_to have_received(:call)
    end
  end

  context "(for a manual that exists, but is neither published, nor draft)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: nil,
          draft: nil
        )
    end

    it "tells none of the listeners to do anything" do
      subject.call
      expect(publishing_api_draft_exporter).not_to have_received(:call)
      expect(publishing_api_publisher).not_to have_received(:call)
      expect(rummager_exporter).not_to have_received(:call)
    end
  end
end
