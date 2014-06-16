class SpecialistDocumentsController < ApplicationController

  before_filter :authorize_user_org

  def index
    documents = services.list_documents(self).call

    render(:index, locals: { documents: documents })
  end

  def show
    document = services.show_document(self).call

    render_or_not_found(:show, document)
  end

  def new
    document = services.new_document(self).call

    render(:new, locals: { document: cma_form(document) })
  end

  def edit
    document = services.show_document(self).call

    render_or_not_found(:edit, cma_form(document))
  end

  def create
    document = services.create_document(self).call

    if document.valid?
      redirect_to(specialist_document_path(document))
    else
      render(:new, locals: {document: document})
    end
  end

  def update
    document = services.update_document(self).call

    if document && document.valid?
      redirect_to(specialist_document_path(document))
    else
      render_or_not_found(:edit, document)
    end
  end

  def publish
    document = services.publish_document(self).call

    redirect_to(specialist_document_path(document))
  end

  def withdraw
    document = services.withdraw_document(self).call

    redirect_to(specialist_documents_path)
  end

  def preview
    preview_html = services.preview_document(self).call

    render json: { preview_html: preview_html }
  end

protected

  def render_or_not_found(action, document)
    if document
      render(action, locals: { document: document })
    else
      redirect_to(manuals_path, flash: { error: "Document not found" })
    end
  end

  def cma_form(document)
    CmaCaseForm.new(document)
  end

  def authorize_user_org
    unless user_can_edit_documents?
      redirect_to manuals_path, flash: { error: "You don't have permission to do that." }
    end
  end
end
