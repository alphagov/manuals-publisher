require "create_section_attachment_service"
require "update_section_attachment_service"
require "show_section_attachment_service"
require "new_section_attachment_service"

class SectionAttachmentsController < ApplicationController
  def new
    service = NewSectionAttachmentService.new(
      repository,
      # TODO: This be should be created from the section or just be a form object
      Attachment.method(:new),
      self,
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
      repository,
      self,
    )
    manual, section, _attachment = service.call

    redirect_to edit_manual_section_path(manual, section)
  end

  def edit
    service = ShowSectionAttachmentService.new(
      repository,
      self,
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
      repository,
      self,
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
    if current_user_is_gds_editor?
      gds_editor_repository
    else
      organisational_repository
    end
  end

  def gds_editor_repository
    RepositoryRegistry.new.manual_repository
  end

  def organisational_repository
    RepositoryRegistry.new.scoped_manual_repository(
      ManualRecord.where(organisation_slug: current_organisation_slug)
    )
  end
end
