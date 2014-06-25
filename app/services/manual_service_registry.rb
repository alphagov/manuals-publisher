class ManualServiceRegistry
  def initialize(dependencies)
    @manual_builder = dependencies.fetch(:manual_builder)
    @manual_repository = dependencies.fetch(:manual_repository)
    @observers = dependencies.fetch(:observers)
  end

  def list(context)
    ListManualsService.new(
      manual_repository: manual_repository,
      context: context,
    )
  end

  def create(context)
    CreateManualService.new(
      manual_repository: manual_repository,
      manual_builder: manual_builder,
      listeners: observers.manual_creation,
      context: context,
    )
  end

  def update(context)
    UpdateManualService.new(
      manual_repository: manual_repository,
      context: context,
    )
  end

  def show(context)
    ShowManualService.new(
      manual_repository: manual_repository,
      context: context,
    )
  end

  def publish(context)
    PublishManualService.new(
      manual_repository: manual_repository,
      listeners: observers.manual_publication,
      context: context,
    )
  end

private
  attr_reader :manual_builder, :manual_repository, :observers
end
