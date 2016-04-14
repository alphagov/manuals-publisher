class PublishSpecialistDocumentWorker
  include Sidekiq::Worker
  attr_reader :logger

  def initialize
    @logger = Logger.new(STDOUT)
  end
  sidekiq_options(
    # This is required to retry in the case of a FailedToPublishError
    retry: 25,
    backtrace: true,
  )

  def perform(edition_id)
    log_queue_length
    edition = specialist_document_editions.find(edition_id)
    document = factory(edition.document_type).call(edition.document_id, [edition])

    rendered_document = formatter.new(
      document,
      specialist_document_renderer: renderer,
      publication_logs: PublicationLog
    )

    exporter.new(
        publishing_api,
        rendered_document,
        document.draft?
    ).call
  rescue => error
    log_error(error)
    requeue_task(edition_id, error)
  end

  private
  def log_queue_length
    logger.info("Sidekiq queue length: #{Sidekiq::Queue.new.size}")
  end

  def specialist_document_editions
    SpecialistDocumentEdition
  end

  def formatter
    SpecialistDocumentPublishingAPIFormatter
  end

  def publishing_api
    SpecialistPublisherWiring.get(:publishing_api)
  end

  def renderer
    SpecialistPublisherWiring.get(:specialist_document_renderer)
  end

  def exporter
    SpecialistDocumentPublishingAPIExporter
  end

  def factory(type)
    entity_factories.public_send("#{type}_factory")
  end

  def entity_factories
    SpecialistPublisherWiring.get(:validatable_document_factories)
  end

  def requeue_task(edition_id, error)
    # Raise a FailedToPublishError in order for Sidekiq to catch and requeue it
    # This is more meaningful when viewing retries in the queue than an error thrown
    # further down the stack!
    raise FailedToPublishError.new("Failed to publish specialist document with id: #{edition_id}", error)
  end

  def log_error(error)
    Airbrake.notify(error)
  end

  class FailedToPublishError < StandardError
    attr_reader :original_exception

    def initialize(message, original_exception = nil)
      super(message)
      @original_exception = original_exception
    end
  end
end
