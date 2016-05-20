require "spec_helper"
require "sidekiq/testing"

RSpec.describe RepublishDocumentWorker do
  it "place job in bulk republishing queue" do
    Sidekiq::Testing.fake! do
      RepublishDocumentWorker.perform_async("1", "doc_type")
      expect(RepublishDocumentWorker.jobs.size).to eq(1)
      expect(RepublishDocumentWorker.jobs.first.fetch("queue")).to eq("bulk_republishing")
    end
  end
end
