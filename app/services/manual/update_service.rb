require "adapters"

class Manual::UpdateService
  def initialize(manual_id:, attributes:, user:)
    @manual_id = manual_id
    @attributes = attributes
    @user = user
  end

  def call
    manual.draft
    update
    persist
    export_draft_to_publishing_api

    manual
  end

private

  attr_reader(
    :manual_id,
    :attributes,
    :user,
  )

  def update
    manual.update(attributes)
  end

  def persist
    manual.save(user)
  end

  def manual
    @manual ||= Manual.find(manual_id, user)
  end

  def export_draft_to_publishing_api
    reloaded_manual = Manual.find(manual.id, user)
    Adapters.publishing.save(reloaded_manual)
  end
end
