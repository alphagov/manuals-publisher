class NewSectionService
  def initialize(manual_repository:, context:)
    @manual_repository = manual_repository
    @context = context
  end

  def call
    [manual, manual.build_section({})]
  end

private

  attr_reader(
    :manual_repository,
    :context,
  )

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def manual_id
    context.params.fetch("manual_id")
  end
end
