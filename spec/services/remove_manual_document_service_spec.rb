require "fast_spec_helper"
require "remove_manual_document_service"

RSpec.describe RemoveManualDocumentService do
  let(:document_id) { "123" }

  let(:manual) {
    double(
      documents: [
        document,
      ],
      remove_document: nil,
    )
  }

  let(:repository) {
    double(
      fetch: manual,
      store: nil,
    )
  }

  let(:service_context) {
    double(
      params: {
        "id" => document_id,
        "manual_id" => "ABC",
      },
    )
  }

  let(:listener) { spy(call: nil) }

  let(:service) {
    described_class.new(
      repository,
      service_context,
      listeners: [listener],
    )
  }

  context "with a section that's previously been published" do
    let(:document) {
      double(
        id: document_id,
        published?: true,
      )
    }

    it "complains" do
      expect {
        service.call
      }.to raise_error(RemoveManualDocumentService::PreviouslyPublishedError)
    end

    it "does not notify the listeners" do
      begin; service.call; rescue; end
      expect(listener).not_to have_received(:call)
    end
  end

  context "with a section that's never been published" do
    let(:document) {
      double(
        id: document_id,
        published?: false,
      )
    }

    before do
      service.call
    end

    it "removes the section" do
      expect(manual).to have_received(:remove_document).with(document_id)
    end

    it "persists the manual" do
      expect(repository).to have_received(:store).with(manual)
    end

    it "notifies its listeners" do
      expect(listener).to have_received(:call).with(document, manual)
    end
  end
end
