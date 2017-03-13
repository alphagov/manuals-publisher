require "update_manual_document_attachment_service"

class AbstractManualDocumentAttachmentServiceRegistry
  def update(context)
    UpdateManualDocumentAttachmentService.new(
      repository,
      context,
    )
  end
end
