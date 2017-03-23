require "spec_helper"
require "support/all_of_matcher"
require "support/govuk_content_schema_helpers"

describe PublishingAPIRedirecter do
  subject {
    described_class.new(
      publishing_api: publishing_api,
      entity: entity,
      redirect_to_location: '/new/slug/for/entity'
    )
  }

  let(:publishing_api) { double(:publishing_api, put_content: nil) }
  let(:entity) { double(:entity, slug: 'original/slug/for/entity') }

  it "exports a redirect valid against the schema" do
    expect(subject.send(:exportable_attributes).to_json).to be_valid_against_schema("redirect")
  end

  it "exports the attributes required for the redirect" do
    allow(subject).to receive(:content_id).and_return('content-id')

    subject.call

    expect(publishing_api).to have_received(:put_content).with(
      'content-id',
      all_of(
        hash_including(
          document_type: 'redirect',
          schema_name: 'redirect',
          publishing_app: 'manuals-publisher',
          base_path: '/original/slug/for/entity',
          redirects: [
            {
              path: '/original/slug/for/entity',
              type: 'exact',
              destination: '/new/slug/for/entity'
            }
          ]
        )
      )
    )
  end
end
