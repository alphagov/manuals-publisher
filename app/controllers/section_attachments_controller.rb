require "create_section_attachment_service"
require "update_section_attachment_service"
require "show_section_attachment_service"
require "new_section_attachment_service"

class SectionAttachmentsController < ApplicationController
  def new
    service = NewSectionAttachmentService.new(
      repository,
      # TODO: This be should be created from the document or just be a form object
      Attachment.method(:new),
      self,
    )
    manual, document, attachment = service.call

    render(:new, locals: {
      manual: ManualViewAdapter.new(manual),
      document: SectionViewAdapter.new(manual, document),
      attachment: attachment,
    })
  end

  def create
    service = CreateSectionAttachmentService.new(
      repository,
      self,
    )
    manual, document, _attachment = service.call

    redirect_to edit_manual_document_path(manual, document)
  end

  def edit
    service = ShowSectionAttachmentService.new(
      repository,
      self,
    )
    manual, document, attachment = service.call

    render(:edit, locals: {
      manual: ManualViewAdapter.new(manual),
      document: SectionViewAdapter.new(manual, document),
      attachment: attachment,
    })
  end

  def update
    service = UpdateSectionAttachmentService.new(
      repository,
      self,
    )
    manual, document, attachment = service.call

    if attachment.persisted?
      redirect_to(edit_manual_document_path(manual, document))
    else
      render(:edit, locals: {
        manual: ManualViewAdapter.new(manual),
        document: SectionViewAdapter.new(manual, document),
        attachment: attachment,
      })
    end
  end

private

  def repository
    if current_user_is_gds_editor?
      gds_editor_repository
    else
      organisational_repository
    end
  end

  def gds_editor_repository
    RepositoryRegistry.create.manual_repository
  end

  def organisational_repository
    manual_repository_factory = RepositoryRegistry.create
      .organisation_scoped_manual_repository_factory
    manual_repository_factory.call(current_organisation_slug)
  end
end
