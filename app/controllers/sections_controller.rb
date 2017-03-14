require "show_section_service"
require "new_section_service"
require "create_section_service"
require "update_section_service"

class SectionsController < ApplicationController
  before_filter :authorize_user_for_withdrawing, only: [:withdraw, :destroy]

  def show
    service = ShowSectionService.new(
      services.manual_repository,
      self,
    )
    manual, section = service.call

    render(:show, locals: {
      manual: manual,
      section: section,
    })
  end

  def new
    service = NewSectionService.new(
      services.manual_repository,
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
      manual_repository: services.manual_repository,
      listeners: [
        services.publishing_api_draft_manual_exporter,
        services.publishing_api_draft_section_exporter
      ],
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
      services.manual_repository,
      self,
    )
    manual, section = service.call

    render(:edit, locals: {
      manual: ManualViewAdapter.new(manual),
      section: SectionViewAdapter.new(manual, section),
    })
  end

  def update
    service = UpdateSectionService.new(
      manual_repository: services.manual_repository,
      context: self,
      listeners: [
        services.publishing_api_draft_manual_exporter,
        services.publishing_api_draft_section_exporter
      ],
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
    section = services.preview(self).call

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
    manual, sections = services.list(self).call

    render(:reorder, locals: {
      manual: ManualViewAdapter.new(manual),
      sections: sections,
    })
  end

  def update_order
    manual, _sections = services.update_order(self).call

    redirect_to(
      manual_path(manual),
      flash: {
        notice: "Order of sections saved for #{manual.title}",
      },
    )
  end

  def withdraw
    service = ShowSectionService.new(
      services.manual_repository,
      self,
    )
    manual, section = service.call

    render(:withdraw, locals: {
      manual: ManualViewAdapter.new(manual),
      section: SectionViewAdapter.new(manual, section),
    })
  end

  def destroy
    manual, section = services.remove(self).call

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

  def services
    if current_user_is_gds_editor?
      gds_editor_services
    else
      organisational_services
    end
  end

  def gds_editor_services
    SectionServiceRegistry.new
  end

  def organisational_services
    OrganisationalSectionServiceRegistry.new(
      organisation_slug: current_organisation_slug,
    )
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
