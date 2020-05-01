require "spec_helper"
require "govuk_sidekiq/testing"

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

  context "when publishing and encountering" do
    let(:publish_service) { double(:publish_service) }
    let(:task) { ManualPublishTask.create! }
    let(:worker) { PublishManualWorker.new }
    let(:logger) { double(:logger, error: nil) }

    before do
      allow(Manual::PublishService).to receive(:new).and_return(publish_service)
      allow(Rails).to receive(:logger).and_return(logger)
    end

    context "an HTTP server error connecting to the GDS API" do
      let(:http_error) { GdsApi::HTTPServerError.new(500) }

      before do
        allow(publish_service).to receive(:call).and_raise(http_error)
      end

      it "raises a failed to publish error so that Sidekiq can retry the job" do
        expect { worker.perform(task.id) }
          .to raise_error(PublishManualWorker::FailedToPublishError)
      end

      it "notifies GovukError of the error" do
        expect(GovukError).to receive(:notify).with(http_error)

        begin
          worker.perform(task.id)
        rescue StandardError
          PublishManualWorker::FailedToPublishError
        end
      end

      it "logs the error to the Rails log" do
        expect(logger).to receive(:error).with(/#{http_error}/)

        begin
          worker.perform(task.id)
        rescue StandardError
          PublishManualWorker::FailedToPublishError
        end
      end
    end

    context "an HTTP error connecting to the GDS API" do
      let(:http_error) { GdsApi::HTTPErrorResponse.new(400) }

      before do
        allow(publish_service).to receive(:call).and_raise(http_error)
      end

      it "stores the error message on the task" do
        allow(http_error).to receive(:message).and_return("http-error-message")
        worker.perform(task.id)
        task.reload
        expect(task.error).to eql("http-error-message")
      end

      it "marks the task as aborted" do
        worker.perform(task.id)
        task.reload
        expect(task).to be_aborted
      end

      it "notifies GovukError of the error" do
        expect(GovukError).to receive(:notify).with(http_error)

        begin
          worker.perform(task.id)
        rescue StandardError
          PublishManualWorker::FailedToPublishError
        end
      end

      it "logs the error to the Rails log" do
        expect(logger).to receive(:error).with(/#{http_error}/)

        begin
          worker.perform(task.id)
        rescue StandardError
          PublishManualWorker::FailedToPublishError
        end
      end
    end

    context "a version mismatch error" do
      let(:version_error) { Manual::PublishService::VersionMismatchError.new }

      before do
        allow(publish_service).to receive(:call).and_raise(version_error)
      end

      it "stores the error message on the task" do
        allow(version_error).to receive(:message).and_return("version-mismatch-message")
        worker.perform(task.id)
        task.reload
        expect(task.error).to eql("version-mismatch-message")
      end

      it "marks the task as aborted" do
        worker.perform(task.id)
        task.reload
        expect(task).to be_aborted
      end

      it "notifies GovukError of the error" do
        expect(GovukError).to receive(:notify).with(version_error)

        begin
          worker.perform(task.id)
        rescue StandardError
          PublishManualWorker::FailedToPublishError
        end
      end

      it "logs the error to the Rails log" do
        expect(logger).to receive(:error).with(/#{version_error}/)

        begin
          worker.perform(task.id)
        rescue StandardError
          PublishManualWorker::FailedToPublishError
        end
      end
    end
  end
end
