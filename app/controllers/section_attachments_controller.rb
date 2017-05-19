class SectionAttachmentsController < ApplicationController
  def new
    service = Attachment::NewService.new(
      user: current_user,
      section_uuid: params.fetch(:section_id),
      manual_id: params.fetch(:manual_id)
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
      attributes: attachment_params,
      section_uuid: params.fetch(:section_id),
      user: current_user,
      manual_id: params.fetch(:manual_id)
    )
    manual, section, _attachment = service.call

    redirect_to edit_manual_section_path(manual, section)
  end

  def edit
    service = Attachment::ShowService.new(
      user: current_user,
      section_uuid: params.fetch(:section_id),
      manual_id: params.fetch(:manual_id),
      attachment_id: params.fetch(:id)
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
      attributes: attachment_params,
      user: current_user,
      attachment_id: params.fetch(:id),
      manual_id: params.fetch(:manual_id),
      section_uuid: params.fetch(:section_id)
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
