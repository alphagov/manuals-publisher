require "spec_helper"
require "sidekiq/testing"

RSpec.describe "Republishing manuals", type: :feature do
  before do
    Sidekiq::Testing.inline!
    login_as(:generic_editor)
    stub_organisation_details(GDS::SSO.test_user.organisation_slug)
  end

  let(:original_publish_time) { DateTime.now - 1.day }
  let(:manual_fields) { { title: "Example manual title", summary: "A summary" } }

  def create_manual_with_sections
    manual = create_manual_without_ui(manual_fields)
    @documents = create_documents_for_manual_without_ui(manual: manual, count: 2)
    @documents.each { |doc| doc.update(exported_at: original_publish_time) }

    # Re-fetch manual to include documents
    @manual = manual_repository.fetch(manual.id)

    publish_manual_without_ui(@manual)

    check_manual_is_drafted_to_publishing_api(@manual.id, number_of_drafts: 3)
    check_manual_is_published_to_publishing_api(@manual.id)

    WebMock::RequestRegistry.instance.reset!
  end

  def republish_manuals
    manual_repository.all.each do |manual|
      ManualServiceRegistry.new.republish(manual.id).call
    end
  end

  def manual_repository
    ManualsPublisherWiring.get(:repository_registry).manual_repository
  end

  describe "republishing a manual with sections" do
    before do
      create_manual_with_sections
    end

    it "sends the manual and the sections to the Publishing API" do
      republish_manuals

      check_manual_is_drafted_to_publishing_api(@manual.id)
      @documents.each do |document|
        check_manual_document_is_drafted_to_publishing_api(document.id)
        check_manual_and_documents_were_published(@manual, document, manual_fields, document_fields(document))
      end
    end

    it "does not change the exported timestamp" do
      expect(@documents.first.latest_edition.reload.exported_at).to be_within(1.second).of original_publish_time
    end
  end
end
