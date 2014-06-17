class ManualsController < ApplicationController
  def index
    all_manuals = services.list(self).call

    render(:index, locals: { manuals: all_manuals })
  end

  def show
    manual = services.show(self).call

    render(:show, locals: { manual: manual })
  end

  def new
    manual = nil

    render(:new, locals: { manual: manual_form(manual) })
  end

  def create
    manual = services.create(self).call
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
    manual = services.show(self).call

    render(:edit, locals: { manual: manual_form(manual) })
  end

  def update
    manual = services.update(self).call
    manual = manual_form(manual)

    if manual.valid?
      redirect_to(manual_path(manual))
    else
      render(:edit, locals: {
        manual: manual,
      })
    end
  end

  def publish
    manual = services.publish(self).call

    redirect_to(manual_path(manual), flash: { notice: "Published #{manual.title}" })
  end

private
  def manual_form(manual)
    ManualForm.new(manual)
  end

  def services
    @services ||= ManualServiceRegistry.new(
      manual_builder: manual_builder,
      manual_repository: manual_repository,
      observers: observers
    )
  end

  def manual_builder
    # TODO Use ManualBuilder.method(:new) instead?
    SpecialistPublisherWiring.get(:manual_builder)
  end

  def manual_repository
    # TODO Get this from a RepositoryRegistry
    SpecialistPublisherWiring.get(:manual_repository_factory).call(
      current_organisation_slug
    )
  end

  def observers
    # TODO Get a set of manual-specific observers
    SpecialistPublisherWiring.get(:observers)
  end
end
