require "list_manuals_service"
require "show_manual_service"
require "create_manual_service"
require "update_manual_service"
require "queue_publish_manual_service"
require "publish_manual_worker"
require "preview_manual_service"
require "builders/manual_builder"
require "manual_observers_registry"

class ManualsController < ApplicationController
  before_filter :authorize_user_for_publishing, only: [:publish]

  def index
    service = ListManualsService.new(
      manual_repository: services.associationless_repository,
      context: self,
    )
    all_manuals = service.call

    render(:index, locals: { manuals: all_manuals })
  end

  def show
    service = ShowManualService.new(
      manual_repository: services.repository,
      manual_id: manual_id,
    )
    manual, metadata = service.call
    slug_unique = metadata.fetch(:slug_unique)
    clashing_sections = metadata.fetch(:clashing_sections)

    unless slug_unique
      flash.now[:error] = "Warning: This manual's URL is already used on GOV.UK. You can't publish it until you change the title."
    end

    render(:show, locals: {
      manual: manual,
      slug_unique: slug_unique,
      clashing_sections: clashing_sections,
    })
  end

  def new
    service = ->() { ManualBuilder.create.call(title: "") }
    manual = service.call

    render(:new, locals: { manual: manual_form(manual) })
  end

  def create
    service = CreateManualService.new(
      manual_repository: services.repository,
      manual_builder: ManualBuilder.create,
      listeners: ManualObserversRegistry.new.creation,
      attributes: create_manual_params,
    )
    manual = service.call
    manual = manual_form(manual)

    if manual.valid?
      redirect_to(manual_path(manual))
    else
      render(:new, locals: {
        manual: manual,
      })
    end
  end

  def edit
    service = ShowManualService.new(
      manual_repository: services.repository,
      manual_id: manual_id,
    )
    manual, _metadata = service.call

    render(:edit, locals: { manual: manual_form(manual) })
  end

  def update
    service = UpdateManualService.new(
      manual_repository: services.repository,
      manual_id: manual_id,
      attributes: update_manual_params,
      listeners: ManualObserversRegistry.new.update,
    )
    manual = service.call
    manual = manual_form(manual)

    if manual.valid?
      redirect_to(manual_path(manual))
    else
      render(:edit, locals: {
        manual: manual,
      })
    end
  end

  def edit_original_publication_date
    service = ShowManualService.new(
      manual_repository: services.repository,
      manual_id: manual_id,
    )
    manual, _metadata = service.call

    render(:edit_original_publication_date, locals: { manual: manual_form(manual) })
  end

  def update_original_publication_date
    service = UpdateManualOriginalPublicationDateService.new(
      manual_repository: services.repository,
      manual_id: manual_id,
      attributes: publication_date_manual_params,
      listeners: ManualObserversRegistry.new.update_original_publication_date,
    )
    manual = service.call
    manual = manual_form(manual)

    if manual.valid?
      redirect_to(manual_path(manual))
    else
      render(:edit_original_publication_date, locals: {
        manual: manual,
      })
    end
  end

  def publish
    service = QueuePublishManualService.new(
      PublishManualWorker,
      services.repository,
      manual_id,
    )
    manual = service.call

    redirect_to(
      manual_path(manual),
      flash: { notice: "Published #{manual.title}" },
    )
  end

  def preview
    service = PreviewManualService.new(
      repository: services.repository,
      builder: ManualBuilder.create,
      renderer: ManualRenderer.new,
      manual_id: params[:id],
      attributes: update_manual_params,
    )
    manual = service.call

    manual.valid? # Force validation check or errors will be empty

    if manual.errors[:body].blank?
      render json: { preview_html: manual.body }
    else
      render json: {
        preview_html: render_to_string(
          "shared/_preview_errors",
          layout: false,
          locals: {
            errors: manual.errors[:body]
          }
        )
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
      .fetch(:manual, {})
      .slice(*only)
      .symbolize_keys
  end

  def valid_params
    %i(
      title
      summary
      body
    )
  end

  def manual_date_params
    date_param_names = [:originally_published_at]
    manual_params = params.fetch(:manual, {})
    date_params = date_param_names.map do |date_param_name|
      [
        date_param_name,
        build_datetime_from(*[
          manual_params.fetch("#{date_param_name}(1i)", ""),
          manual_params.fetch("#{date_param_name}(2i)", ""),
          manual_params.fetch("#{date_param_name}(3i)", ""),
          manual_params.fetch("#{date_param_name}(4i)", ""),
          manual_params.fetch("#{date_param_name}(5i)", ""),
          manual_params.fetch("#{date_param_name}(6i)", ""),
        ])
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

  def services
    if current_user_is_gds_editor?
      gds_editor_services
    else
      organisational_services
    end
  end

  def gds_editor_services
    ManualServiceRegistry.new
  end

  def organisational_services
    OrganisationalManualServiceRegistry.new(
      organisation_slug: current_organisation_slug,
    )
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
