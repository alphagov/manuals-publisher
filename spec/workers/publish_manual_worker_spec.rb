require "spec_helper"
require "sidekiq/testing"

RSpec.describe PublishManualWorker do
  after do
    GdsApi::GovukHeaders.clear_headers
  end

  it "places job in the default queue" do
    Sidekiq::Testing.fake! do
      PublishManualWorker.perform_async("1")
      expect(PublishManualWorker.jobs.size).to eq(1)
      expect(PublishManualWorker.jobs.first.fetch("queue")).to eq("default")
    end
  end

  it "repopulates worker request headers" do
    task = double(:task, start!: nil, finish!: nil, manual_id: 1, version_number: 2)
    expect(ManualPublishTask).to receive(:find).with("1").and_return(task)
    expect(Manual::PublishService).to receive(:new).and_return(double(:publish, call: nil))

    Sidekiq::Testing.inline! do
      PublishManualWorker.perform_async("1", request_id: "12345", authenticated_user: "abc123")
      expect(GdsApi::GovukHeaders.headers[:govuk_request_id]).to eq("12345")
      expect(GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user]).to eq("abc123")
    end
  end

  context 'when encountering an HTTP server error connecting to the GDS API' do
    let(:publish_service) { double(:publish_service) }
    let(:task) { ManualPublishTask.create! }
    let(:worker) { PublishManualWorker.new }
    let(:http_error) { GdsApi::HTTPServerError.new(500) }

    before do
      allow(Manual::PublishService).to receive(:new).and_return(publish_service)
      allow(publish_service).to receive(:call).and_raise(http_error)
    end

    it 'raises a failed to publish error so that Sidekiq can retry the job' do
      expect { worker.perform(task.id) }
        .to raise_error(PublishManualWorker::FailedToPublishError)
    end

    it 'notifies Airbrake of the error' do
      expect(Airbrake).to receive(:notify).with(http_error)

      worker.perform(task.id) rescue PublishManualWorker::FailedToPublishError
    end
  end
end
