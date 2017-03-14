require "preview_manual_document_service"
require "create_manual_document_service"
require "update_manual_document_service"
require "show_manual_document_service"
require "new_manual_document_service"
require "list_manual_documents_service"
require "reorder_manual_documents_service"
require "remove_manual_document_service"

class AbstractManualDocumentServiceRegistry
  def preview(context)
    PreviewManualDocumentService.new(
      manual_repository,
      manual_document_builder,
      document_renderer,
      context,
    )
  end

  def create(context)
    CreateManualDocumentService.new(
      manual_repository: manual_repository,
      listeners: [
        publishing_api_draft_manual_exporter,
        publishing_api_draft_manual_document_exporter
      ],
      context: context,
    )
  end

  def update(context)
    UpdateManualDocumentService.new(
      manual_repository: manual_repository,
      context: context,
      listeners: [
        publishing_api_draft_manual_exporter,
        publishing_api_draft_manual_document_exporter
      ],
    )
  end

  def show(context)
    ShowManualDocumentService.new(
      manual_repository,
      context,
    )
  end

  def new(context)
    NewManualDocumentService.new(
      manual_repository,
      context,
    )
  end

  def list(context)
    ListManualDocumentsService.new(
      manual_repository,
      context,
    )
  end

  def update_order(context)
    ReorderManualDocumentsService.new(
      manual_repository,
      context,
      listeners: [publishing_api_draft_manual_exporter]
    )
  end

  def remove(context)
    RemoveManualDocumentService.new(
      manual_repository,
      context,
      listeners: [
        publishing_api_draft_manual_exporter,
        publishing_api_draft_manual_document_discarder
      ]
    )
  end

private

  def document_renderer
    SectionRenderer.new
  end

  def manual_document_builder
    ManualDocumentBuilder.create
  end

  def manual_repository
    raise NotImplementedError
  end

  def organisation(slug)
    OrganisationFetcher.instance.call(slug)
  end

  def publishing_api_draft_manual_exporter
    ->(_, manual) {
      ManualPublishingAPILinksExporter.new(
        publishing_api_v2.method(:patch_links),
        organisation(manual.attributes.fetch(:organisation_slug)),
        manual
      ).call

      ManualPublishingAPIExporter.new(
        publishing_api_v2.method(:put_content),
        organisation(manual.attributes.fetch(:organisation_slug)),
        ManualRenderer.new,
        PublicationLog,
        manual
      ).call
    }
  end

  def publishing_api_draft_manual_document_exporter
    ->(manual_document, manual) {
      SectionPublishingAPILinksExporter.new(
        publishing_api_v2.method(:patch_links),
        organisation(manual.attributes.fetch(:organisation_slug)),
        manual,
        manual_document
      ).call

      SectionPublishingAPIExporter.new(
        publishing_api_v2.method(:put_content),
        organisation(manual.attributes.fetch(:organisation_slug)),
        ManualDocumentRenderer.new,
        manual,
        manual_document
      ).call
    }
  end

  def publishing_api_draft_manual_document_discarder
    ->(manual_document, _manual) {
      begin
        publishing_api_v2.discard_draft(manual_document.id)
      rescue GdsApi::HTTPNotFound, GdsApi::HTTPUnprocessableEntity # rubocop:disable Lint/HandleExceptions
      end
    }
  end

  def publishing_api_v2
    PublishingApiV2.instance
  end

  def organisations_api
    GdsApi::Organisations.new(ORGANISATIONS_API_BASE_PATH)
  end
end
