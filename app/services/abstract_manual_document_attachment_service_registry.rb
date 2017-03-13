require "update_manual_document_attachment_service"
require "show_manual_document_attachment_service"

class AbstractManualDocumentAttachmentServiceRegistry
  def update(context)
    UpdateManualDocumentAttachmentService.new(
      repository,
      context,
    )
  end

  def show(context)
    ShowManualDocumentAttachmentService.new(
      repository,
      context,
    )
  end
end
