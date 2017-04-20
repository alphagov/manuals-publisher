class Section::ListService
  def initialize(context:)
    @context = context
  end

  def call
    [manual, sections]
  end

private

  attr_reader :context

  def sections
    manual.sections
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def manual_id
    context.params.fetch("manual_id")
  end
end
