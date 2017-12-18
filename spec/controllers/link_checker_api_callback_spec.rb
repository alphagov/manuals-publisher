require "spec_helper"
require "gds_api/test_helpers/link_checker_api"

RSpec.describe LinkCheckerApiCallbackController, type: :controller do
  include GdsApi::TestHelpers::LinkCheckerApi

  def generate_signature(body, key)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), key, body)
  end

  let(:service) { double(:service, call: nil) }
  let(:link_check_report) { LinkCheckReport.new }
  let(:post_body) do
    link_checker_api_batch_report_hash(
      id: 5,
      links: [
        { uri: @link, status: "ok" },
      ]
    )
  end

  before do
    allow(LinkCheckReport).to receive(:find_by).with(batch_id: 5).and_return(link_check_report)
    expect(LinkCheckReport::UpdateService).to receive(:new).and_return(service)
  end

  it "POST :update updates LinkCheckReport" do
    headers = {
      "Content-Type": "application/json",
      "X-LinkCheckerApi-Signature": generate_signature(post_body.to_json, Rails.application.secrets.link_checker_api_secret_token)
    }

    request.headers.merge! headers
    post :callback, params: post_body
  end
end
