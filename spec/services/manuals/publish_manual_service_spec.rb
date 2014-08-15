require "fast_spec_helper"
require "manuals/publish_manual_service"

RSpec.describe PublishManualService do

  let(:manual_id) { double(:manual_id) }
  let(:manual_repository) { double(:manual_repository) }
  let(:listeners) { [] }
  let(:manual) { double(:manual, id: manual_id, version_number: 3) }

  subject {
    PublishManualService.new(
      manual_id: manual_id,
      manual_repository: manual_repository,
      listeners: listeners,
      version_number: version_number,
    )
  }

  before do
    allow(manual_repository).to receive(:fetch) { manual }
    allow(manual_repository).to receive(:store)
    allow(manual).to receive(:publish)
  end

  context "when the version number is up to date" do
    let(:version_number) { 3 }

    it "publishes the manual" do
      subject.call
      expect(manual).to have_received(:publish)
    end
  end

  context "when the version numbers differ" do
    let(:version_number) { 4 }

    it "should raise a PublishManualService::VersionMismatchError" do
      expect { subject.call }.to raise_error(PublishManualService::VersionMismatchError)
    end
  end
end
