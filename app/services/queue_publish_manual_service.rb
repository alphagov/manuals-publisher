class QueuePublishManualService

  def initialize(worker, repository, manual_id)
    @worker = worker
    @repository = repository
    @manual_id = manual_id
  end

  def call
    task = create_publish_task(manual)
    worker.perform_async(task.to_param, govuk_header_params)
    manual
  end

private

  attr_reader(
    :worker,
    :repository,
    :manual_id,
  )

  def create_publish_task(manual)
    ManualPublishTask.create!(
      manual_id: manual.id,
      version_number: manual.version_number,
    )
  end

  def manual
    @manual ||= repository.fetch(manual_id)
  end

  def govuk_header_params
    {
      request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
      authenticated_user: GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user],
    }
  end
end
