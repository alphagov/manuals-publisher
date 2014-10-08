require "preview_manual_document_service"
require "create_manual_document_service"
require "destroy_manual_document_service"
require "update_manual_document_service"
require "show_manual_document_service"
require "new_manual_document_service"

class ManualDocumentServiceRegistry
  def preview(context)
    PreviewManualDocumentService.new(
      manual_repository(context),
      manual_document_builder,
      document_renderer,
      context,
    )
  end

  def create(context)
    CreateManualDocumentService.new(
      manual_repository: manual_repository(context),
      listeners: [],
      context: context,
    )
  end

  def destroy(context)
    DestroyManualDocumentService.new(
      manual_repository: manual_repository(context),
      manual_id: context.params.fetch("manual_id"),
      document_id: context.params.fetch("id"),
    )
  end

  def update(context)
    UpdateManualDocumentService.new(
      manual_repository(context),
      context,
    )
  end

  def show(context)
    ShowManualDocumentService.new(
      manual_repository(context),
      context,
    )
  end

  def new(context)
    NewManualDocumentService.new(
      manual_repository(context),
      context,
    )
  end

private
  def document_renderer
    SpecialistPublisherWiring.get(:specialist_document_renderer)
  end

  def manual_repository_factory
    SpecialistPublisherWiring.get(:organisational_manual_repository_factory)
  end

  def manual_document_builder
    SpecialistPublisherWiring.get(:manual_document_builder)
  end

  # XXX This is far too tied to a controller context. If it depends on knowing
  # about an organisation slug, let's pass that in rather than the entire
  # context.
  def manual_repository(context)
    manual_repository_factory.call(context.current_organisation_slug)
  end
end
