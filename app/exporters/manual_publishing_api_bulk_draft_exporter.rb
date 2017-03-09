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
    raise 'GdsApi::PublishingApi#put_draft_content_item was removed in gds-api-adapters v38.0.0'
  end

private

  def count_manuals
    @manuals_count ||= RepositoryRegistry.create.associationless_manual_repository.all.count
  end

  def organisation(slug)
    OrganisationFetcher.instance.call(slug)
  end

  def manual_renderer
    ManualRenderer.create
  end

  def manual_document_renderer
    ManualDocumentRenderer.create
  end
end
