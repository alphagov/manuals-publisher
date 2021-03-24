class SectionsController < ApplicationController
  before_action :authorize_user_for_withdrawing, only: %i[withdraw destroy]

  def show
    service = Section::ShowService.new(
      user: current_user,
      manual_id: params.fetch(:manual_id),
      section_uuid: params.fetch(:id),
    )
    manual, section = service.call

    render(
      :show,
      locals: {
        manual: manual,
        section: section,
      },
    )
  end

  def new
    service = Section::NewService.new(
      user: current_user,
      manual_id: params.fetch(:manual_id),
    )
    manual, section = service.call

    render(
      :new,
      locals: {
        manual: ManualViewAdapter.new(manual),
        section: SectionViewAdapter.new(manual, section),
      },
    )
  end

  def create
    service = Section::CreateService.new(
      user: current_user,
      manual_id: params.fetch(:manual_id),
      attributes: section_params,
    )
    manual, section = service.call

    if section.valid?
      redirect_to(manual_path(manual))
    else
      render(
        :new,
        locals: {
          manual: ManualViewAdapter.new(manual),
          section: SectionViewAdapter.new(manual, section),
        },
      )
    end
  end

  def edit
    service = Section::ShowService.new(
      user: current_user,
      manual_id: params.fetch(:manual_id),
      section_uuid: params.fetch(:id),
    )
    manual, section = service.call

    render(
      :edit,
      locals: {
        manual: ManualViewAdapter.new(manual),
        section: SectionViewAdapter.new(manual, section),
      },
    )
  end

  def update
    service = Section::UpdateService.new(
      user: current_user,
      manual_id: params.fetch(:manual_id),
      section_uuid: params.fetch(:id),
      attributes: section_params,
    )
    manual, section = service.call

    if section.valid?
      redirect_to(manual_path(manual))
    else
      render(
        :edit,
        locals: {
          manual: ManualViewAdapter.new(manual),
          section: SectionViewAdapter.new(manual, section),
        },
      )
    end
  end

  def preview
    service = Section::PreviewService.new(
      user: current_user,
      manual_id: params.fetch(:manual_id, nil),
      section_uuid: params.fetch(:id, nil),
      attributes: section_params,
    )
    section = SectionPresenter.new(service.call)

    section.valid? # Force validation check or errors will be empty

    if section.errors[:body].empty?
      render json: { preview_html: section.body }
    else
      render json: {
        preview_html: render_to_string(
          "shared/_preview_errors",
          layout: false,
          locals: {
            errors: section.errors[:body],
          },
        ),
      }
    end
  end

  def reorder
    service = Section::ListService.new(
      user: current_user,
      manual_id: params.fetch(:manual_id),
    )
    manual, sections = service.call

    render(
      :reorder,
      locals: {
        manual: ManualViewAdapter.new(manual),
        sections: sections,
      },
    )
  end

  def update_order
    service = Section::ReorderService.new(
      user: current_user,
      manual_id: params.fetch(:manual_id),
      section_order: params.fetch(:section_order),
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
    service = Section::ShowService.new(
      user: current_user,
      manual_id: params.fetch(:manual_id),
      section_uuid: params.fetch(:id),
    )
    manual, section = service.call

    render(
      :withdraw,
      locals: {
        manual: ManualViewAdapter.new(manual),
        section: SectionViewAdapter.new(manual, section),
      },
    )
  end

  def destroy
    service = Section::RemoveService.new(
      user: current_user,
      manual_id: params.fetch(:manual_id),
      section_uuid: params.fetch(:id),
      attributes: section_params,
    )
    manual, section = service.call

    if section.valid?
      redirect_to(
        manual_path(manual),
        flash: {
          notice: "Section #{section.title} removed!",
        },
      )
    else
      render(
        :withdraw,
        locals: {
          manual: ManualViewAdapter.new(manual),
          section: SectionViewAdapter.new(manual, section),
        },
      )
    end
  end

private

  def section_params
    params
      .require(:section)
      .permit(:title, :summary, :body, :change_note, :minor_update, :visually_expanded)
      .to_h
      .symbolize_keys
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
