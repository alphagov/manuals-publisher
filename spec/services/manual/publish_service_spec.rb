require "spec_helper"
require "ostruct"

RSpec.describe Manual::PublishService do
  let(:manual_id) { double(:manual_id) }
  let(:manual) { double(:manual, id: manual_id, version_number: 3) }
  let(:publication_logger) { double(:publication_logger) }
  let(:publishing_adapter) { double(:publishing_adapter) }
  let(:search_index_adapter) { double(:search_index_adapter) }
  let(:user) { double(:user) }

  subject {
    Manual::PublishService.new(
      user: user,
      manual_id: manual_id,
      version_number: version_number
    )
  }

  before do
    allow(Manual).to receive(:find) { manual }
    allow(manual).to receive(:save)
    allow(manual).to receive(:publish)
    allow(PublicationLogger).to receive(:new) { publication_logger }
    allow(Adapters).to receive(:publishing) { publishing_adapter }
    allow(Adapters).to receive(:search_index) { search_index_adapter }
    allow(publication_logger).to receive(:call)
    allow(publishing_adapter).to receive(:save)
    allow(publishing_adapter).to receive(:publish)
    allow(search_index_adapter).to receive(:add)
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
      expect(publishing_adapter).to have_received(:save).with(manual)
    end

    it "calls the new publishing api publisher" do
      subject.call
      expect(publishing_adapter).to have_received(:publish).with(manual)
    end

    it "adds the manual to the search index" do
      subject.call
      expect(search_index_adapter).to have_received(:add).with(manual)
    end

    it "makes the calls to the collaborators in the correct order" do
      subject.call

      expect(publication_logger).to have_received(:call).ordered
      expect(publishing_adapter).to have_received(:save).ordered
      expect(publishing_adapter).to have_received(:publish).ordered
      expect(search_index_adapter).to have_received(:add).ordered
    end
  end

  context "when the version numbers differ" do
    let(:version_number) { 4 }

    it "should raise a Manual::PublishService::VersionMismatchError" do
      expect { subject.call }.to raise_error(Manual::PublishService::VersionMismatchError)
    end
  end
end
