require "spec_helper"

require "manual_repository"

describe ManualRepository do
  subject(:repo) {
    ManualRepository.new(record_collection)
  }

  let(:record_collection) {
    double(:record_collection,
      find_or_initialize_by: nil,
    )
  }

  let(:manual_id) { double(:manual_id) }
  let(:manual_slug) { double(:manual_slug) }
  let(:originally_published_at) { double(:originally_published_at) }
  let(:use_originally_published_at_for_public_timestamp) { double(:use_originally_published_at_for_public_timestamp) }

  let(:manual) { double(:manual, manual_attributes) }

  let(:manual_attributes) {
    {
      id: manual_id,
      title: "title",
      state: "draft",
      summary: "summary",
      body: "body",
      organisation_slug: "organisation_slug",
      slug: manual_slug,
      ever_been_published: true,
      originally_published_at: originally_published_at,
      use_originally_published_at_for_public_timestamp: use_originally_published_at_for_public_timestamp,
    }
  }

  let(:manual_record) {
    double(
      :manual_record,
      manual_id: manual_id,
      new_or_existing_draft_edition: nil,
      organisation_slug: "organisation_slug",
      "organisation_slug=": nil,
      slug: manual_slug,
      "slug=": nil,
      latest_edition: nil,
      save!: nil,
      has_ever_been_published?: true,
    )
  }

  let(:edition) { double(:edition, edition_messages) }
  let(:edition_messages) {
    edition_attributes.merge(
      :attributes= => nil,
    )
  }
  let(:edition_attributes) {
    {
      title: "title",
      summary: "summary",
      body: "body",
      updated_at: "yesterday",
      organisation_slug: "organisation_slug",
      state: "draft",
      slug: manual_slug,
      version_number: 1,
      ever_been_published: true,
      originally_published_at: originally_published_at,
      use_originally_published_at_for_public_timestamp: use_originally_published_at_for_public_timestamp,
    }
  }
end
