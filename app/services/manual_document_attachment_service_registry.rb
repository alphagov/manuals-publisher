require "manual_document_attachments/create_manual_document_attachment_service"
require "manual_document_attachments/update_manual_document_attachment_service"
require "manual_document_attachments/show_manual_document_attachment_service"
require "manual_document_attachments/new_manual_document_attachment_service"

class ManualDocumentAttachmentServiceRegistry
  def create(context)
    CreateManualDocumentAttachmentService.new(
      manual_repository(context),
      context,
    )
  end

  def update(context)
    UpdateManualDocumentAttachmentService.new(
      manual_repository(context),
      context,
    )
  end

  def show(context)
    ShowManualDocumentAttachmentService.new(
      manual_repository(context),
      context,
    )
  end

  def new(context)
    NewManualDocumentAttachmentService.new(
      manual_repository(context),
      # TODO: This be should be created from the document or just be a form object
      Attachment.method(:new),
      context,
    )
  end

private
  def manual_repository_factory
    SpecialistPublisherWiring.get(:organisational_manual_repository_factory)
  end

  def manual_repository(context)
    manual_repository_factory.call(context.current_organisation_slug)
  end
end
