class LinkCheckerApiCallbackController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_signin_permission!
  skip_before_action :set_authenticated_user_header
  before_action :verify_signature

  def callback
    report = LinkCheckReport.find_by(batch_id: params.require(:id))

    if report
      LinkCheckReport::UpdateService.new(
        report: report,
        params: params
      ).call
    end

    head :no_content
  end

private

  def verify_signature
    return unless webhook_secret_token
    given_signature = request.headers["X-LinkCheckerApi-Signature"]
    return head :bad_request unless given_signature
    body = request.raw_post
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), webhook_secret_token, body)
    head :bad_request unless Rack::Utils.secure_compare(signature, given_signature)
  end

  def webhook_secret_token
    Rails.application.secrets.link_checker_api_secret_token
  end
end
