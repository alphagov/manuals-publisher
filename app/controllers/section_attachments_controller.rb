class SectionAttachmentsController < ApplicationController
  def new
    service = Attachment::NewService.new(
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
    service = Attachment::CreateService.new(
      file: attachment_params.fetch(:file),
      title: attachment_params.fetch(:title),
      section_uuid: params.fetch(:section_id),
      user: current_user,
      manual_id: params.fetch(:manual_id)
    )
    manual, section, _attachment = service.call

    redirect_to edit_manual_section_path(manual, section)
  end

  def edit
    service = Attachment::ShowService.new(
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
    service = Attachment::UpdateService.new(
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

  def attachment_params
    params.require("attachment").permit(:title, :file)
  end
end
