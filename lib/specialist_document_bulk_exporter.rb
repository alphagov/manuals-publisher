class SpecialistDocumentBulkExporter
  attr_reader :type, :formatter, :exporter, :logger, :worker

  def initialize(type,
                 formatter: SpecialistDocumentPublishingAPIFormatter,
                 exporter: SpecialistDocumentPublishingAPIExporter,
                 worker: PublishSpecialistDocumentWorker,
                 logger: Logger.new(nil))
    @formatter = formatter
    @exporter = exporter
    @logger = logger
    @type = type
    @worker = worker
  end

  def call
    export_all_editions("published")
    export_all_editions("draft")
  end

  private

  def export_all_editions(state)
    editions = specialist_document_editions.where(state: state)
    logger.info("Exporting #{editions.count} #{state} #{type} documents")

    editions.each_with_index do |edition, i|
      logger.info(i) if i % 10 == 0
      export_edition(edition)
    end
  end

  def export_edition(edition)
    worker.perform_async(edition.id.to_s)
  end

  def specialist_document_editions
    SpecialistDocumentEdition.where(document_type: type)
  end
end
