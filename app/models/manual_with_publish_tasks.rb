require "delegate"

class ManualWithPublishTasks < SimpleDelegator
  def initialize(manual, publish_tasks:)
    super(manual)
    @publish_tasks = publish_tasks
  end

  def publish_tasks
    @publish_tasks.to_enum
  end
end
