class Manual::ShowService
  def initialize(manual_id:, context:)
    @manual_id = manual_id
    @context = context
  end

  def call
    manual
  end

private

  attr_reader(
    :manual_id,
    :context,
  )

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end
end
