class ManualPublishTaskAssociationMarshaller
  def load(manual, _record)
    tasks = ManualPublishTask.for_manual(manual)

    ManualWithPublishTasks.new(manual, publish_tasks: tasks)
  end

  def dump(_manual, _record)
    # PublishTasks are read only
    nil
  end
end
