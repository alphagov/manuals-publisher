require "rails_helper"
require "sidekiq/testing"

RSpec.describe RepublishDocumentWorker do

  after do
    GdsApi::GovukHeaders.clear_headers
  end

  it "place job in bulk republishing queue" do
    Sidekiq::Testing.fake! do
      RepublishDocumentWorker.perform_async("1", "doc_type")
      expect(RepublishDocumentWorker.jobs.size).to eq(1)
      expect(RepublishDocumentWorker.jobs.first.fetch("queue")).to eq("bulk_republishing")
    end
  end

  it "place job in bulk republishing queue" do
    expect(ManualsPublisher).to receive(:document_services)
      .and_return(double(:service, republish: double(:thing, call: nil)))

    Sidekiq::Testing.inline! do
      RepublishDocumentWorker.perform_async("1", "doc_type", request_id: "12345", authenticated_user: "abc123")
      expect(GdsApi::GovukHeaders.headers[:govuk_request_id]).to eq("12345")
      expect(GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user]).to eq("abc123")
    end
  end
end
