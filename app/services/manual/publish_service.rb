require "adapters"

class Manual::PublishService
  def initialize(user:, manual_id:, version_number:)
    @user = user
    @manual_id = manual_id
    @version_number = version_number
  end

  def call
    manual = Manual.find(manual_id, user)

    if version_number == manual.version_number
      manual.publish
      PublicationLogger.new.call(manual)
      Adapters.publishing.save_draft(manual)
      Adapters.publishing.publish(manual)
      manual.save!(user)
    else
      raise VersionMismatchError,
            %(The manual with id '#{manual.id}' could not be published due to a version mismatch.
          The version to publish was '#{version_number}' but the current version was '#{manual.version_number}')
    end

    manual
  end

private

  attr_reader :user, :manual_id, :version_number

  class VersionMismatchError < StandardError
  end
end
