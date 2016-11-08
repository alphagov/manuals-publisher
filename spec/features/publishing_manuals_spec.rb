require "spec_helper"
require "sidekiq/testing"

RSpec.describe "Republishing manuals", type: :feature do
  before do
    Sidekiq::Testing.inline!
    login_as(:generic_editor)
    stub_organisation_details(GDS::SSO.test_user.organisation_slug)
  end

  let(:manual_fields) { { title: "Example manual title", summary: "A summary" } }

  def manual_repository
    ManualsPublisherWiring.get(:repository_registry).manual_repository
  end

  describe "publishing a manual with major and minor updates" do
    before do
      manual = create_manual_without_ui(manual_fields)

      @documents = [].tap do |documents|
        documents << create_manual_document_without_ui(manual, { title: "Section 1 major", summary: "Section 1 summary", body: "Section body" })
        documents << create_manual_document_without_ui(manual, { title: "Section 1", summary: "Section 1 minor summary", body: "Section body minor update", minor_update: true })
      end

      # Re-fetch manual to include documents
      @manual = manual_repository.fetch(manual.id)

      publish_manual_without_ui(@manual)
    end

    it "sends the manual and the sections to the Publishing API" do
      @documents.each do |document|
        check_manual_and_documents_were_published(@manual, document, manual_fields, document_fields(document))
      end
    end

    it "creates publication logs for major updates to documents only" do
      expect(PublicationLog.count).to eq 1
      expect(PublicationLog.first.title).to eq "Section 1 major"
    end
  end
end
