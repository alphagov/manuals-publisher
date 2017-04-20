class Section::NewService
  def initialize(context:)
    @context = context
  end

  def call
    [manual, manual.build_section({})]
  end

private

  attr_reader(
    :context,
  )

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def manual_id
    context.params.fetch("manual_id")
  end
end
