require "show_section_service"
require "new_section_service"
require "create_section_service"
require "update_section_service"
require "preview_section_service"
require "list_sections_service"
require "reorder_sections_service"
require "remove_section_service"

class SectionsController < ApplicationController
  before_filter :authorize_user_for_withdrawing, only: [:withdraw, :destroy]

  def show
    service = ShowSectionService.new(
      manual_repository: manual_repository,
      context: self,
    )
    manual, section = service.call

    render(:show, locals: {
      manual: manual,
      section: section,
    })
  end

  def new
    service = NewSectionService.new(
      manual_repository,
      self,
    )
    manual, section = service.call

    render(:new, locals: {
      manual: ManualViewAdapter.new(manual),
      section: SectionViewAdapter.new(manual, section)
    })
  end

  def create
    service = CreateSectionService.new(
      manual_repository: manual_repository,
      context: self,
    )
    manual, section = service.call

    if section.valid?
      redirect_to(manual_path(manual))
    else
      render(:new, locals: {
        manual: ManualViewAdapter.new(manual),
        section: SectionViewAdapter.new(manual, section),
      })
    end
  end

  def edit
    service = ShowSectionService.new(
      manual_repository: manual_repository,
      context: self,
    )
    manual, section = service.call

    render(:edit, locals: {
      manual: ManualViewAdapter.new(manual),
      section: SectionViewAdapter.new(manual, section),
    })
  end

  def update
    service = UpdateSectionService.new(
      manual_repository: manual_repository,
      context: self,
    )
    manual, section = service.call

    if section.valid?
      redirect_to(manual_path(manual))
    else
      render(:edit, locals: {
        manual: ManualViewAdapter.new(manual),
        section: SectionViewAdapter.new(manual, section),
      })
    end
  end

  def preview
    service = PreviewSectionService.new(
      manual_repository,
      SectionBuilder.new,
      SectionRenderer.new,
      self,
    )
    section = service.call

    section.valid? # Force validation check or errors will be empty

    if section.errors[:body].nil?
      render json: { preview_html: section.body }
    else
      render json: {
        preview_html: render_to_string(
          "shared/_preview_errors",
          layout: false,
          locals: {
            errors: section.errors[:body]
          }
        )
      }
    end
  end

  def reorder
    service = ListSectionsService.new(
      manual_repository,
      self,
    )
    manual, sections = service.call

    render(:reorder, locals: {
      manual: ManualViewAdapter.new(manual),
      sections: sections,
    })
  end

  def update_order
    service = ReorderSectionsService.new(
      manual_repository,
      self,
    )
    manual, _sections = service.call

    redirect_to(
      manual_path(manual),
      flash: {
        notice: "Order of sections saved for #{manual.title}",
      },
    )
  end

  def withdraw
    service = ShowSectionService.new(
      manual_repository: manual_repository,
      context: self,
    )
    manual, section = service.call

    render(:withdraw, locals: {
      manual: ManualViewAdapter.new(manual),
      section: SectionViewAdapter.new(manual, section),
    })
  end

  def destroy
    service = RemoveSectionService.new(
      manual_repository,
      self,
    )
    manual, section = service.call

    if section.valid?
      redirect_to(
        manual_path(manual),
        flash: {
          notice: "Section #{section.title} removed!"
        }
      )
    else
      render(:withdraw, locals: {
        manual: ManualViewAdapter.new(manual),
        section: SectionViewAdapter.new(manual, section),
      })
    end
  end

private

  def manual_repository
    ScopedManualRepository.new(current_user.manual_records)
  end

  def authorize_user_for_withdrawing
    unless current_user_can_withdraw?
      redirect_to(
        manual_section_path(params[:manual_id], params[:id]),
        flash: { error: "You don't have permission to withdraw manual sections." },
      )
    end
  end
end
