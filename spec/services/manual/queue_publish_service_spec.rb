require "spec_helper"
require "ostruct"

RSpec.describe Manual::QueuePublishService do
  let(:manual_id) { double(:manual_id) }
  let(:manual) { double(:manual, id: manual_id, version_number: 1, draft?: draft) }
  let(:draft) { true }
  let(:user) { double(:user) }

  subject { Manual::QueuePublishService.new(user: user, manual_id: manual_id) }

  before do
    allow(Manual).to receive(:find) { manual }
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

    it "should raise a Manual::QueuePublishService::InvalidStateError" do
      expect { subject.call }.to raise_error(Manual::QueuePublishService::InvalidStateError)
    end
  end
end
