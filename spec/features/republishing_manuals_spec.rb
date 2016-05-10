require "spec_helper"
require "sidekiq/testing"

RSpec.describe "Republishing manuals", type: :feature do
  before do
    Sidekiq::Testing.inline!
    login_as(:generic_editor)
    stub_organisation_details(GDS::SSO.test_user.organisation_slug)
  end

  let(:manual_fields) { { title: "Example manual title", summary: "A summary" } }
  let(:manual_slug) { "guidance/example-manual-title" }

  def create_manual_with_sections
    @manual_fields = manual_fields # this is necessary to be able to use `create_documents_for_manual` from `manual_helpers`

    create_manual(manual_fields)
    @attributes_for_documents = create_documents_for_manual(manual_fields: manual_fields, count: 2)
    publish_manual

    check_manual_is_published_to_publishing_api(manual_slug)
    WebMock::RequestRegistry.instance.reset!
  end

  def republish_manuals
    repository = SpecialistPublisherWiring.get(:repository_registry).manual_repository
    repository.all.each do |manual|
      ManualServiceRegistry.new.republish(manual.id).call
    end
  end

  describe "republishing a manual with sections" do
    before do
      create_manual_with_sections
    end

    it "sends the manual and the sections to the Publishing API" do
      republish_manuals

      @attributes_for_documents.each do |document_attributes|
        check_manual_and_documents_were_published(
          manual_slug,
          manual_fields,
          document_attributes[:slug],
          document_attributes[:fields],
        )
      end
    end
  end
end
