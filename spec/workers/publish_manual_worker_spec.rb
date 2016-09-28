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
    expect(PublishManualService).to receive(:new).and_return(double(:publish, call: nil))

    Sidekiq::Testing.inline! do
      PublishManualWorker.perform_async("1", { request_id: "12345", authenticated_user: "abc123" })
      expect(GdsApi::GovukHeaders.headers[:govuk_request_id]).to eq("12345")
      expect(GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user]).to eq("abc123")
    end
  end
end
