class PublishManualWorker
  include Sidekiq::Worker

  sidekiq_options(
    retry: 25,
    backtrace: true,
  )

  def perform(task_id)
    task = ManualPublishTask.find(task_id)
    task.start!

    services.publish(task.manual_id, task.version_number).call

    task.finish!
  rescue PanopticonRegisterer::ServerError => error
    requeue_task(task_id, error)
  rescue PanopticonRegisterer::ClientError => error
    abort_task(task, error)
  rescue StandardError => error
    abort_task(task, error)
  ensure
    log_error(error)
  end

private
  def services
    ManualServiceRegistry.new
  end

  def requeue_task(manual_id, error)
    raise FailedToPublishError.new("Failed to publish manual with id: #{manual_id}", error)
  end

  def abort_task(task, error)
    task.update_attribute(:error, error.message)
    task.abort!
  end

  def log_error(error)
    Airbrake.notify(error)
  end

  class FailedToPublishError < StandardError
    attr_reader :original_exception

    def initialize(message, original_exception = nil)
      super(message)
      @original_exception = original_exception
    end
  end
end
