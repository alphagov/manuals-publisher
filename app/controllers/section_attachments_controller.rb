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
      context: self,
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
end
