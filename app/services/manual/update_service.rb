require "adapters"

class Manual::UpdateService
  def initialize(manual_id:, attributes:, context:)
    @manual_id = manual_id
    @attributes = attributes
    @context = context
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
    :context,
  )

  def update
    manual.update(attributes)
  end

  def persist
    manual.save(context.current_user)
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def export_draft_to_publishing_api
    reloaded_manual = Manual.find(manual.id, context.current_user)
    Adapters.publishing.save(reloaded_manual)
  end
end
