require "preview_section_service"
require "create_section_service"
require "update_section_service"
require "show_section_service"
require "new_section_service"
require "list_sections_service"
require "reorder_manual_documents_service"
require "remove_section_service"
require "services"

class AbstractSectionServiceRegistry
  def preview(context)
    PreviewSectionService.new(
      manual_repository,
      manual_document_builder,
      document_renderer,
      context,
    )
  end

  def create(context)
    CreateSectionService.new(
      manual_repository: manual_repository,
      listeners: [
        publishing_api_draft_manual_exporter,
        publishing_api_draft_manual_document_exporter
      ],
      context: context,
    )
  end

  def update(context)
    UpdateSectionService.new(
      manual_repository: manual_repository,
      context: context,
      listeners: [
        publishing_api_draft_manual_exporter,
        publishing_api_draft_manual_document_exporter
      ],
    )
  end

  def show(context)
    ShowSectionService.new(
      manual_repository,
      context,
    )
  end

  def new(context)
    NewSectionService.new(
      manual_repository,
      context,
    )
  end

  def list(context)
    ListSectionsService.new(
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
    RemoveSectionService.new(
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
    SectionBuilder.create
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
        organisation(manual.attributes.fetch(:organisation_slug)),
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
    Services.publishing_api_v2
  end

  def organisations_api
    Services.organisations
  end
end
