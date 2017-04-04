require "spec_helper"
require "publish_manual_service"
require "ostruct"

RSpec.describe PublishManualService do
  let(:manual_id) { double(:manual_id) }
  let(:manual) { double(:manual, id: manual_id, version_number: 3) }
  let(:publication_logger) { double(:publication_logger) }
  let(:publishing_api_draft_exporter) { double(:publishing_api_draft_exporter) }
  let(:new_publishing_api_publisher) { double(:new_publishing_api_publisher) }
  let(:rummager_exporter) { double(:rummager_exporter) }
  let(:user) { double(:user) }
  let(:context) { double(:context, current_user: user) }

  subject {
    PublishManualService.new(
      manual_id: manual_id,
      version_number: version_number,
      context: context,
    )
  }

  before do
    allow(Manual).to receive(:find) { manual }
    allow(manual).to receive(:save)
    allow(manual).to receive(:publish)
    allow(PublicationLogger).to receive(:new) { publication_logger }
    allow(PublishingApiDraftManualWithSectionsExporter).to receive(:new) { publishing_api_draft_exporter }
    allow(PublishingApiManualWithSectionsPublisher).to receive(:new) { new_publishing_api_publisher }
    allow(RummagerManualWithSectionsExporter).to receive(:new) { rummager_exporter }
    allow(publication_logger).to receive(:call)
    allow(publishing_api_draft_exporter).to receive(:call)
    allow(new_publishing_api_publisher).to receive(:call)
    allow(rummager_exporter).to receive(:call)
  end

  context "when the version number is up to date" do
    let(:version_number) { 3 }

    it "publishes the manual" do
      subject.call
      expect(manual).to have_received(:publish)
    end

    it "calls the publication logger" do
      subject.call
      expect(publication_logger).to have_received(:call).with(manual)
    end

    it "calls the publishing api draft exporter" do
      subject.call
      expect(publishing_api_draft_exporter).to have_received(:call).with(manual)
    end

    it "calls the new publishing api publisher" do
      subject.call
      expect(new_publishing_api_publisher).to have_received(:call).with(manual)
    end

    it "calls the rummager exporter" do
      subject.call
      expect(rummager_exporter).to have_received(:call).with(manual)
    end

    it "makes the calls to the collaborators in the correct order" do
      subject.call

      expect(publication_logger).to have_received(:call).ordered
      expect(publishing_api_draft_exporter).to have_received(:call).ordered
      expect(new_publishing_api_publisher).to have_received(:call).ordered
      expect(rummager_exporter).to have_received(:call).ordered
    end
  end

  context "when the version numbers differ" do
    let(:version_number) { 4 }

    it "should raise a PublishManualService::VersionMismatchError" do
      expect { subject.call }.to raise_error(PublishManualService::VersionMismatchError)
    end
  end
end
