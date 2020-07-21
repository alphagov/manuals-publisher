require "spec_helper"
require "gds_api/test_helpers/content_store"
require "gds_api_constants"

describe SectionReslugger do
  include GdsApi::TestHelpers::ContentStore
  include GdsApi::TestHelpers::Organisations
  include GdsApi::TestHelpers::PublishingApi

  subject do
    described_class.new(
      "manual-slug",
      "manual-slug/old-section-slug",
      "manual-slug/new-section-slug",
    )
  end

  before do
    manual_record = ManualRecord.create!(
      manual_id: "manual-id",
      slug: "manual-slug",
      organisation_slug: "organisation-slug",
    )
    SectionEdition.create!(
      section_uuid: "section-id",
      slug: "manual-slug/old-section-slug",
      title: "section-edition-title",
      summary: "section-edition-summary",
      body: "section-edition-body",
    )
    manual_record.editions.create!(
      section_uuids: %w[section-id],
    )

    stub_content_store_has_item("/manual-slug/old-section-slug")
    stub_content_store_does_not_have_item("/manual-slug/new-section-slug")

    stub_organisations_api_has_organisation("organisation-slug")

    stub_any_publishing_api_patch_links
    stub_any_publishing_api_put_content
    stub_any_publishing_api_publish
  end

  it "doesn't raise any exceptions" do
    subject.call
  end
end
