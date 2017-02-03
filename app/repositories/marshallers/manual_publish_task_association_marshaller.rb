class ManualPublishTaskAssociationMarshaller
  def initialize(decorator:, collection:)
    @decorator = decorator
    @collection = collection
  end

  def load(manual, _record)
    tasks = collection.for_manual(manual)

    decorator.call(manual, publish_tasks: tasks)
  end

  def dump(_manual, _record)
    # PublishTasks are read only
    nil
  end

private
  attr_reader :collection, :decorator
end
