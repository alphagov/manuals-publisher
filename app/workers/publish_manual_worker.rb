class PublishManualWorker
  include Sidekiq::Worker

  sidekiq_options(
    # This is required to retry in the case of a FailedToPublishError
    retry: 25,
    backtrace: true,
  )

  def perform(task_id, _params = {})
    task = ManualPublishTask.find(task_id)
    task.start!

    service = Manual::PublishService.new(
      user: User.gds_editor,
      manual_id: task.manual_id,
      version_number: task.version_number,
    )
    service.call

    task.finish!
  rescue GdsApi::HTTPServerError => e
    log_error(e)
    requeue_task(task_id, e)
  rescue Manual::PublishService::VersionMismatchError,
         GdsApi::HTTPErrorResponse => e
    log_error(e)
    abort_task(task, e)
  end

private

  def requeue_task(manual_id, error)
    # Raise a FailedToPublishError in order for Sidekiq to catch and requeue it
    # This is more meaningful when viewing retries in the queue than an error thrown
    # further down the stack!
    raise FailedToPublishError.new("Failed to publish manual with id: #{manual_id}", error)
  end

  def abort_task(task, error)
    task.update!(error: error.message)
    task.abort!
  end

  def log_error(error)
    Rails.logger.error "#{self.class} error: #{error}"
    GovukError.notify(error)
  end

  class FailedToPublishError < StandardError
    attr_reader :original_exception

    def initialize(message, original_exception = nil)
      super(message)
      @original_exception = original_exception
    end
  end
end
