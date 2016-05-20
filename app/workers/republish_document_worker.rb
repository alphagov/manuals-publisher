class RepublishDocumentWorker
  include Sidekiq::Worker

  sidekiq_options(
    # This is required to retry in the case of a FailedToPublishError
    retry: 25,
    backtrace: true,
    queue: "bulk_republishing",
  )

  def perform(document_id, type)
    services = SpecialistPublisher.document_services(type)
    services.republish(document_id).call
  end
end
