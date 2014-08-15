require "specialist_publisher_wiring"
require "specialist_documents/list_documents_service"
require "specialist_documents/show_document_service"
require "specialist_documents/new_document_service"
require "specialist_documents/preview_document_service"
require "specialist_documents/create_document_service"
require "specialist_documents/update_document_service"
require "specialist_documents/publish_document_service"
require "specialist_documents/withdraw_document_service"
require "paginator"

class AbstractDocumentServiceRegistry
  def list
    ListDocumentsService.new(
      RepositoryPaginator.new(document_repository),
    )
  end

  def show(document_id)
    ShowDocumentService.new(
      document_repository,
      document_id,
    )
  end

  def new
    NewDocumentService.new(
      document_builder,
    )
  end

  def preview(document_id, attributes)
    PreviewDocumentService.new(
      document_repository,
      document_builder,
      document_renderer,
      document_id,
      attributes,
    )
  end

  def create(attributes)
    CreateDocumentService.new(
      document_builder,
      document_repository,
      observers.creation,
      attributes,
    )
  end

  def update(document_id, attributes)
    UpdateDocumentService.new(
      repo: document_repository,
      listeners: observers.update,
      document_id: document_id,
      attributes: attributes,
    )
  end

  def publish(document_id)
    PublishDocumentService.new(
      document_repository,
      observers.publication,
      document_id,
    )
  end

  def withdraw(document_id)
    WithdrawDocumentService.new(
      document_repository,
      observers.withdrawal,
      document_id,
    )
  end

private
  def document_renderer
    SpecialistPublisherWiring.get(:specialist_document_renderer)
  end

  def document_repository
    raise NotImplementedError
  end

  def document_builder
    raise NotImplementedError
  end

  def observers
    raise NotImplementedError
  end
end
