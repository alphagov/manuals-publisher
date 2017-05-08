class Manual::CreateService
  def initialize(attributes:, context:)
    @attributes = attributes
    @context = context
  end

  def call
    if manual.valid?
      persist
      export_draft_to_publishing_api
    end

    manual
  end

private

  attr_reader(
    :attributes,
    :context,
  )

  def manual
    @manual ||= Manual.build(attributes)
  end

  def persist
    manual.save(context.current_user)
  end

  def export_draft_to_publishing_api
    reloaded_manual = Manual.find(manual.id, context.current_user)
    Adapters.publishing.save(reloaded_manual)
  end
end
