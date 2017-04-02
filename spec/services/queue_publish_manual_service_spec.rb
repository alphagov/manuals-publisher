require "spec_helper"
require "queue_publish_manual_service"
require "ostruct"

RSpec.describe QueuePublishManualService do
  let(:manual_id) { double(:manual_id) }
  let(:repository) { double(:repository) }
  let(:manual) { double(:manual, id: manual_id, version_number: 1, draft?: draft) }
  let(:draft) { true }
  let(:context) { double(:context) }

  subject { QueuePublishManualService.new(repository: repository, manual_id: manual_id, context: context) }

  before do
    allow(repository).to receive(:fetch) { manual }
    allow(PublishManualWorker).to receive(:perform_async)
  end

  context "when the manual is a draft" do
    let(:draft) { true }

    it "worker performs task asynchronously" do
      subject.call
      expect(PublishManualWorker).to have_received(:perform_async)
    end
  end

  context "when the manual is not a draft" do
    let(:draft) { false }

    it "should raise a QueuePublishManualService::InvalidStateError" do
      expect { subject.call }.to raise_error(QueuePublishManualService::InvalidStateError)
    end
  end
end
