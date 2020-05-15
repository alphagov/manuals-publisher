require "publish_manual_worker"

class ManualsController < ApplicationController
  before_action :authorize_user_for_publishing, only: [:publish]

  def index
    service = Manual::ListService.new(
      user: current_user,
    )
    all_manuals = service.call

    render(:index, locals: { manuals: all_manuals })
  end

  def show
    service = Manual::ShowService.new(
      manual_id: manual_id,
      user: current_user,
    )
    manual = service.call
    slug_unique = manual.slug_unique?(current_user)
    clashing_sections = manual.clashing_sections

    unless slug_unique
      flash.now[:error] = "Warning: This manual's URL is already used on GOV.UK. You can't publish it until you change the title."
    end

    render(
      :show,
      locals: {
        manual: manual,
        slug_unique: slug_unique,
        clashing_sections: clashing_sections,
      },
    )
  end

  def new
    service = -> { Manual.new }
    manual = service.call

    render(:new, locals: { manual: manual_form(manual) })
  end

  def create
    service = Manual::CreateService.new(
      user: current_user,
      attributes: create_manual_params,
    )
    manual = service.call
    manual = manual_form(manual)

    if manual.valid?
      redirect_to(manual_path(manual))
    else
      render(
        :new,
        locals: {
          manual: manual,
        },
      )
    end
  end

  def edit
    service = Manual::ShowService.new(
      manual_id: manual_id,
      user: current_user,
    )
    manual = service.call

    render(:edit, locals: { manual: manual_form(manual) })
  end

  def update
    service = Manual::UpdateService.new(
      user: current_user,
      manual_id: manual_id,
      attributes: update_manual_params,
    )
    manual = service.call
    manual = manual_form(manual)

    if manual.valid?
      redirect_to(manual_path(manual))
    else
      render(
        :edit,
        locals: {
          manual: manual,
        },
      )
    end
  end

  def edit_original_publication_date
    service = Manual::ShowService.new(
      manual_id: manual_id,
      user: current_user,
    )
    manual = service.call

    render(:edit_original_publication_date, locals: { manual: manual_form(manual) })
  end

  def update_original_publication_date
    service = Manual::UpdateOriginalPublicationDateService.new(
      user: current_user,
      manual_id: manual_id,
      attributes: publication_date_manual_params,
    )
    manual = service.call
    manual = manual_form(manual)

    if manual.valid?
      redirect_to(manual_path(manual))
    else
      render(
        :edit_original_publication_date,
        locals: {
          manual: manual,
        },
      )
    end
  end

  def publish
    service = Manual::QueuePublishService.new(
      user: current_user,
      manual_id: manual_id,
    )
    manual = service.call

    redirect_to(
      manual_path(manual),
      flash: { notice: "Published #{manual.title}" },
    )
  end

  def discard_draft
    service = Manual::DiscardDraftService.new(
      user: current_user,
      manual_id: manual_id,
    )
    result = service.call

    if result.successful?
      redirect_to(
        manuals_path,
        flash: { notice: "Discarded draft of #{result.manual_title}" },
      )
    else
      redirect_to(
        manual_path(manual_id),
        flash: { notice: "Unable to discard draft of #{result.manual_title}" },
      )
    end
  end

  def preview
    service = Manual::PreviewService.new(
      user: current_user,
      manual_id: params[:id],
      attributes: update_manual_params,
    )
    manual = ManualPresenter.new(service.call)

    manual.valid? # Force validation check or errors will be empty

    if manual.errors[:body].blank?
      render json: { preview_html: manual.body }
    else
      render json: {
        preview_html: render_to_string(
          "shared/_preview_errors",
          layout: false,
          locals: {
            errors: manual.errors[:body],
          },
        ),
      }
    end
  end

private

  def manual_id
    params.fetch(:id)
  end

  def create_manual_params
    base_manual_params
      .merge(manual_date_params)
      .merge(
        use_originally_published_at_for_public_timestamp: "1",
        organisation_slug: current_organisation_slug,
      )
  end

  def update_manual_params
    base_manual_params
  end

  def publication_date_manual_params
    base_manual_params(only: [:use_originally_published_at_for_public_timestamp])
      .merge(manual_date_params)
  end

  def base_manual_params(only: valid_params)
    params
      .require(:manual)
      .permit(*only)
      .to_h
      .symbolize_keys
  end

  def valid_params
    %i[
      title
      summary
      body
    ]
  end

  def manual_date_params
    date_param_names = [:originally_published_at]
    manual_params = params.require(:manual).permit(*date_param_names)
    date_params = date_param_names.map do |date_param_name|
      [
        date_param_name,
        build_datetime_from(
          manual_params.fetch("#{date_param_name}(1i)", ""),
          manual_params.fetch("#{date_param_name}(2i)", ""),
          manual_params.fetch("#{date_param_name}(3i)", ""),
          manual_params.fetch("#{date_param_name}(4i)", ""),
          manual_params.fetch("#{date_param_name}(5i)", ""),
          manual_params.fetch("#{date_param_name}(6i)", ""),
        ),
      ]
    end
    Hash[date_params]
  end

  def build_datetime_from(*date_args)
    return nil if date_args.all?(&:blank?)

    Time.zone.local(*date_args.map(&:to_i))
  end

  def manual_form(manual)
    ManualViewAdapter.new(manual)
  end

  def authorize_user_for_publishing
    unless current_user_can_publish?
      redirect_to(
        manual_path(manual_id),
        flash: { error: "You don't have permission to publish." },
      )
    end
  end
end
