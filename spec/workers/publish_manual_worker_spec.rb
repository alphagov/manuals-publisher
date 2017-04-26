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
    let(:logger) { double(:logger, error: nil) }

    before do
      allow(Manual::PublishService).to receive(:new).and_return(publish_service)
      allow(publish_service).to receive(:call).and_raise(http_error)
      allow(Rails).to receive(:logger).and_return(logger)
    end

    it 'raises a failed to publish error so that Sidekiq can retry the job' do
      expect { worker.perform(task.id) }
        .to raise_error(PublishManualWorker::FailedToPublishError)
    end

    it 'notifies Airbrake of the error' do
      expect(Airbrake).to receive(:notify).with(http_error)

      worker.perform(task.id) rescue PublishManualWorker::FailedToPublishError
    end

    it 'logs the error to the Rails log' do
      expect(logger).to receive(:error).with(/#{http_error}/)

      worker.perform(task.id) rescue PublishManualWorker::FailedToPublishError
    end
  end

  context 'when encountering an HTTP error connecting to the GDS API' do
    let(:publish_service) { double(:publish_service) }
    let(:task) { ManualPublishTask.create! }
    let(:worker) { PublishManualWorker.new }
    let(:http_error) { GdsApi::HTTPErrorResponse.new(400) }
    let(:logger) { double(:logger, error: nil) }

    before do
      allow(Manual::PublishService).to receive(:new).and_return(publish_service)
      allow(publish_service).to receive(:call).and_raise(http_error)
      allow(Rails).to receive(:logger).and_return(logger)
    end

    it 'stores the error message on the task' do
      allow(http_error).to receive(:message).and_return('http-error-message')
      worker.perform(task.id)
      task.reload
      expect(task.error).to eql('http-error-message')
    end

    it 'marks the task as aborted' do
      worker.perform(task.id)
      task.reload
      expect(task).to be_aborted
    end

    it 'notifies Airbrake of the error' do
      expect(Airbrake).to receive(:notify).with(http_error)

      worker.perform(task.id) rescue PublishManualWorker::FailedToPublishError
    end

    it 'logs the error to the Rails log' do
      expect(logger).to receive(:error).with(/#{http_error}/)

      worker.perform(task.id) rescue PublishManualWorker::FailedToPublishError
    end
  end

  context 'when encountering a version mismatch error' do
    let(:publish_service) { double(:publish_service) }
    let(:task) { ManualPublishTask.create! }
    let(:worker) { PublishManualWorker.new }
    let(:version_error) { Manual::PublishService::VersionMismatchError.new }
    let(:logger) { double(:logger, error: nil) }

    before do
      allow(Manual::PublishService).to receive(:new).and_return(publish_service)
      allow(publish_service).to receive(:call).and_raise(version_error)
      allow(Rails).to receive(:logger).and_return(logger)
    end

    it 'stores the error message on the task' do
      allow(version_error).to receive(:message).and_return('version-mismatch-message')
      worker.perform(task.id)
      task.reload
      expect(task.error).to eql('version-mismatch-message')
    end

    it 'marks the task as aborted' do
      worker.perform(task.id)
      task.reload
      expect(task).to be_aborted
    end

    it 'notifies Airbrake of the error' do
      expect(Airbrake).to receive(:notify).with(version_error)

      worker.perform(task.id) rescue PublishManualWorker::FailedToPublishError
    end

    it 'logs the error to the Rails log' do
      expect(logger).to receive(:error).with(/#{version_error}/)

      worker.perform(task.id) rescue PublishManualWorker::FailedToPublishError
    end
  end
end
