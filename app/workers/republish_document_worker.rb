class RepublishDocumentWorker
  include Sidekiq::Worker

  sidekiq_options(
    # This is required to retry in the case of a FailedToPublishError
    retry: 25,
    backtrace: true,
    queue: "bulk_republishing",
  )

  def perform(document_id, type, params = {}, _govuk_headers = nil)
    GdsApi::GovukHeaders.set_header(:govuk_request_id, params["request_id"])
    GdsApi::GovukHeaders.set_header(:x_govuk_authenticated_user, params["authenticated_user"])

    services = SpecialistPublisher.document_services(type)
    services.republish(document_id).call
  end
end
