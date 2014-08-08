class ManualPublishTaskAssociationMarshaller
  def initialize(dependencies = {})
    @decorator = dependencies.fetch(:decorator)
    @collection = dependencies.fetch(:collection)
  end

  def load(manual, record)
    tasks = collection.where(
      manual_id: manual.id,
    ).order("version_number DESC")

    decorator.call(manual, publish_tasks: tasks)
  end

  def dump(manual, record)
    # PublishTasks are read only
    nil
  end

private
  attr_reader :collection, :decorator
end
