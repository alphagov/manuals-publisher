require "spec_helper"
require "gds_api/test_helpers/link_checker_api"

RSpec.describe LinkCheckerApiCallbackController, type: :controller do
  include GdsApi::TestHelpers::LinkCheckerApi

  def generate_signature(body, key)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA1.new, key, body)
  end

  def set_headers
    headers = {
      "Content-Type": "application/json",
      "X-LinkCheckerApi-Signature": generate_signature(post_body.to_json, Rails.application.secrets.link_checker_api_secret_token),
    }

    request.headers.merge! headers
  end

  let(:link_check_report_batch_id) { 5 }
  let(:link_check_report) do
    FactoryBot.create(
      :link_check_report,
      :with_pending_links,
      batch_id: 5,
      manual_id: 1,
      link_uris: ["https://gov.uk"],
    )
  end

  let(:post_body) do
    link_checker_api_batch_report_hash(
      id: link_check_report_batch_id,
      links: [
        { uri: @link, status: "ok" },
      ],
    )
  end

  context "when the report exists" do
    subject do
      post :callback, params: post_body
      link_check_report.reload
    end

    before do
      allow(LinkCheckReport).to receive(:find_by).with(batch_id: 5).and_return(link_check_report)
    end

    it "POST :update updates LinkCheckReport" do
      set_headers

      expect { subject }.to change { link_check_report.status }.to("completed")
    end
  end

  context "when the report does not exist" do
    let(:link_check_report_batch_id) { 1 }

    it "should not throw an error" do
      set_headers
      post :callback, params: post_body

      expect(response.status).to eq(204)
    end
  end
end
