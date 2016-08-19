require "fast_spec_helper"
require "support/govuk_content_schema_helpers"
require "publishing_api_withdrawer"

RSpec.describe PublishingAPIWithdrawer do
  let(:publishing_api) { double("PublishingAPI") }
  let(:entity) { double("Entity", slug: "some-slug") }
  let(:subject) { PublishingAPIWithdrawer.new(publishing_api: publishing_api, entity: entity) }

  it "exports a gone item valid against the schema" do
    expect(subject.send(:exportable_attributes).to_json).to be_valid_against_schema("gone")
  end

  it "exports schema name" do
    expect(subject.send(:exportable_attributes)).to include(:schema_name)
  end
end
