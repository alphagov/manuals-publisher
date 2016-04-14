require "spec_helper"
require "lib/specialist_document_bulk_exporter"
require "sidekiq/testing"

describe SpecialistDocumentBulkExporter do
  let(:exporter) {
    double("SpecialistDocumentPublishingAPIExporter", new: double(call: {}))
  }

  let(:worker) {
    PublishSpecialistDocumentWorker
  }

  before do
    Sidekiq::Testing.fake!
  end

  subject {
    described_class.new(
      "cma_case",
      exporter: exporter,
      worker: worker
    )
  }

  let!(:edition1) {
    FactoryGirl.create(
      :specialist_document_edition,
      document_id: SecureRandom.uuid,
      document_type: "cma_case",
      updated_at: 2.days.ago,
      title: "Original title",
      body: "",
      state: "published",
    )
  }

  let!(:edition2) {
    FactoryGirl.create(
      :specialist_document_edition,
      document_id: edition1.document_id,
      document_type: "cma_case",
      updated_at: 1.day.ago,
      body: "",
      title: "Updated title",
      state: "draft",
    )
  }

  let!(:edition3) {
    FactoryGirl.create(
      :specialist_document_edition,
      document_id: edition1.document_id,
      document_type: "cma_case",
      updated_at: 3.days.ago,
      title: "Unrelated title",
      body: "",
      state: "archived",
    )
  }

  it "adds draft and published specialist-documents to sidekiq queue" do
    subject.call
    expect(worker.jobs.size).to eq(2)
  end
end
