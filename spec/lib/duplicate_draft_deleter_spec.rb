require "rails_helper"
require "duplicate_draft_deleter"
require "gds_api/test_helpers/publishing_api_v2"

describe DuplicateDraftDeleter do
  include GdsApi::TestHelpers::PublishingApiV2

  it "deletes duplicate editions that aren't present in Publishing API" do
    original_content_id = SecureRandom.uuid
    edition = FactoryGirl.create(:specialist_document_edition,
      slug: "cma-cases/a-case",
      document_id: original_content_id,
      document_type: "cma_case",
      state: "draft",
    )
    publishing_api_has_item(content_id: original_content_id)

    duplicate_content_id = SecureRandom.uuid
    duplicate_edition = FactoryGirl.create(:specialist_document_edition,
      slug: "cma-cases/a-case",
      document_id: duplicate_content_id,
      document_type: "cma_case",
      state: "draft",
    )
    another_duplicate_edition_with_same_content_id = FactoryGirl.create(:specialist_document_edition,
      slug: "cma-cases/a-case",
      document_id: duplicate_content_id,
      document_type: "cma_case",
      state: "archived",
    )
    publishing_api_does_not_have_item(duplicate_content_id)

    expected_output = /The following 2 editions are unknown to Publishing API and will be deleted:.*#{duplicate_content_id}/m
    expect { DuplicateDraftDeleter.new.call }.to output(expected_output).to_stdout

    expect(SpecialistDocumentEdition.where(document_id: original_content_id)).to be_present
    expect(SpecialistDocumentEdition.where(document_id: duplicate_content_id)).to be_empty
  end

  it "leaves non-duplicated editions alone" do
    content_id = SecureRandom.uuid
    edition = FactoryGirl.create(:specialist_document_edition,
      document_id: content_id,
    )

    another_content_id = SecureRandom.uuid
    edition = FactoryGirl.create(:specialist_document_edition,
      document_id: another_content_id,
    )

    expect { DuplicateDraftDeleter.new.call }.to output.to_stdout

    expect(SpecialistDocumentEdition.where(document_id: content_id)).to be_present
    expect(SpecialistDocumentEdition.where(document_id: another_content_id)).to be_present
  end
end
