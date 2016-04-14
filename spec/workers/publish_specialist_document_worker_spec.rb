require "sidekiq/testing"
require "spec_helper"
Sidekiq::Testing.inline!

RSpec.describe "Publish specialist document worker" do
  let(:subject) { PublishSpecialistDocumentWorker }

  let!(:edition1) {
    FactoryGirl.create(
      :specialist_document_edition,
      document_id: SecureRandom.uuid,
      document_type: "cma_case",
      updated_at: 2.days.ago,
      title: "Original title",
      body: "",
      state: "published",
      slug: "specialist-document-1"
    )
  }

  it "should PUT specialist document payload to publishing-api" do
    stub_default_publishing_api_put
    worker = subject.new
    worker.perform(edition1.id.to_s)
    assert_publishing_api_put_item("/specialist-document-1")
  end

  it "should log response to Airbrake and requeue task if publishing-api does not return http status 200" do
    publishing_api_isnt_available
    expect(Airbrake).to receive(:notify)
    worker = subject.new
    expect {worker.perform(edition1.id.to_s)}.to raise_error(PublishSpecialistDocumentWorker::FailedToPublishError)
  end

end
