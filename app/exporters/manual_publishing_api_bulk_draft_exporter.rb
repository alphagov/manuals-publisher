class ManualPublishingApiBulkDraftExporter
  attr_reader :wiring, :logger

  def initialize(wiring, logger: Logger.new(nil))
    @wiring = wiring
    @logger = logger
  end

  def export_all
    logger.info("Exporting #{count_manuals} manuals to the DRAFT publishing api")

    RepositoryRegistry.create.manual_repository.all.each do |manual|
      export_one(manual)
    end

    logger.info("Export complete")
  end

  def export_one(manual)
    logger.info("Exporting manual: '#{manual.id}' '#{manual.attributes[:slug]}'")
    organisation = organisation(manual.attributes.fetch(:organisation_slug))

    ManualPublishingAPIExporter.new(
      export_recipient,
      organisation,
      manual_renderer,
      PublicationLog,
      manual
    ).call

    count = manual.documents.count
    logger.info("Exporting #{count} documents...")

    manual.documents.each do |document|
      logger.info("Exporting document: '#{document.id}' '#{document.slug}'")

      ManualSectionPublishingAPIExporter.new(
        export_recipient,
        organisation,
        manual_document_renderer,
        manual,
        document
      ).call
    end

    logger.info("Exporting of manual: '#{manual.id}' complete")
  end

private
  def count_manuals
    @manuals_count ||= RepositoryRegistry.create.associationless_manual_repository.all.count
  end

  def export_recipient
    PublishingApi.instance.method(:put_draft_content_item)
  end

  def organisation(slug)
    wiring.get(:organisation_fetcher).call(slug)
  end

  def manual_renderer
    ManualRenderer.create
  end

  def manual_document_renderer
    ManualDocumentRenderer.create
  end
end
