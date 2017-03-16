require "spec_helper"
require "queue_publish_manual_service"
require "ostruct"

RSpec.describe QueuePublishManualService do
  let(:manual_id) { double(:manual_id) }
  let(:repository) { double(:repository) }
  let(:worker) { double(:worker, perform_async: nil) }
  let(:manual) { double(:manual, id: manual_id, version_number: 1, draft?: draft) }
  let(:draft) { true }

  subject { QueuePublishManualService.new(worker, repository, manual_id) }

  before do
    allow(repository).to receive(:fetch) { manual }
  end

  context "when the manual is a draft" do
    let(:draft) { true }

    it "worker performs task asynchronously" do
      subject.call
      expect(worker).to have_received(:perform_async)
    end
  end

  context "when the manual is not a draft" do
    let(:draft) { false }

    it "should raise a QueuePublishManualService::InvalidStateError" do
      expect { subject.call }.to raise_error(QueuePublishManualService::InvalidStateError)
    end
  end
end
