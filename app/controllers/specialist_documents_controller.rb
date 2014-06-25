class SpecialistDocumentsController < ApplicationController

  before_filter :authorize_user_org

  rescue_from(KeyError) do
    # TODO: Remove use of exceptions for flow control.
    redirect_to(manuals_path, flash: { error: "Document not found" })
  end

  def index
    documents = services.list_documents(
      self,
      document_type: document_type,
    ).call

    render(:index, locals: { documents: documents })
  end

  def show
    document = services.show_document(
      self,
      document_type: document_type,
    ).call

    render(:show, locals: { document: document })
  end

  def new
    document = services.new_document(
      self,
      document_type: document_type,
    ).call

    render(:new, locals: { document: form_object_for(document) })
  end

  def edit
    document = services.show_document(
      self,
      document_type: document_type,
    ).call

    render(:edit, locals: { document: form_object_for(document) })
  end

  def create
    document = services.create_document(
      self,
      document_type: document_type,
    ).call

    if document.valid?
      redirect_to(specialist_document_path(document))
    else
      render(:new, locals: {document: document})
    end
  end

  def update
    document = services.update_document(
      self,
      document_type: document_type,
    ).call

    if document.valid?
      redirect_to(specialist_document_path(document))
    else
      render(:edit, locals: {document: document})
    end
  end

  def publish
    document = services.publish_document(self).call

    redirect_to(specialist_document_path(document), flash: { notice: "Published #{document.title}" })
  end

  def withdraw
    document = services.withdraw_document(self).call

    redirect_to(specialist_documents_path, flash: { error: "Withdrawn #{document.title}" })
  end

  def preview
    preview_html = services.preview_document(self).call

    render json: { preview_html: preview_html }
  end

protected

  def form_object_for(document)
    case current_organisation_slug
    when "competition-and-markets-authority"
      CmaCaseForm.new(document)
    end
  end

  def authorize_user_org
    unless user_can_edit_documents?
      redirect_to manuals_path, flash: { error: "You don't have permission to do that." }
    end
  end
end
