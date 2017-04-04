require "create_section_attachment_service"
require "update_section_attachment_service"
require "show_section_attachment_service"
require "new_section_attachment_service"

class SectionAttachmentsController < ApplicationController
  def new
    service = NewSectionAttachmentService.new(
      manual_repository: repository,
      # TODO: This be should be created from the section or just be a form object
      builder: Attachment.method(:new),
      context: self,
    )
    manual, section, attachment = service.call

    render(:new, locals: {
      manual: ManualViewAdapter.new(manual),
      section: SectionViewAdapter.new(manual, section),
      attachment: attachment,
    })
  end

  def create
    service = CreateSectionAttachmentService.new(
      manual_repository: repository,
      context: self,
    )
    manual, section, _attachment = service.call

    redirect_to edit_manual_section_path(manual, section)
  end

  def edit
    service = ShowSectionAttachmentService.new(
      manual_repository: repository,
      context: self,
    )
    manual, section, attachment = service.call

    render(:edit, locals: {
      manual: ManualViewAdapter.new(manual),
      section: SectionViewAdapter.new(manual, section),
      attachment: attachment,
    })
  end

  def update
    service = UpdateSectionAttachmentService.new(
      manual_repository: repository,
      context: self,
    )
    manual, section, attachment = service.call

    if attachment.persisted?
      redirect_to(edit_manual_section_path(manual, section))
    else
      render(:edit, locals: {
        manual: ManualViewAdapter.new(manual),
        section: SectionViewAdapter.new(manual, section),
        attachment: attachment,
      })
    end
  end

private

  def repository
    ScopedManualRepository.new(current_user.manual_records)
  end
end
