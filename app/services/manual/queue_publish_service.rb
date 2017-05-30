require "manual_publish_task"

class Manual::QueuePublishService
  def initialize(user:, manual_id:)
    @user = user
    @manual_id = manual_id
  end

  def call
    manual = Manual.find(manual_id, user)

    if manual.draft?
      task = ManualPublishTask.create!(
        manual_id: manual.id,
        version_number: manual.version_number,
      )

      govuk_header_params = {
        request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
        authenticated_user: GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user],
      }

      PublishManualWorker.perform_async(task.to_param, govuk_header_params)
      manual
    else
      raise InvalidStateError.new(
        "The manual with id '#{manual.id}' could not be published as it was not in a draft state."
      )
    end
  end

private

  attr_reader :user, :manual_id

  class InvalidStateError < StandardError
  end
end
