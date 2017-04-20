class Attachment::ShowService
  def initialize(context:)
    @context = context
  end

  def call
    [manual, section, attachment]
  end

private

  attr_reader :context

  def attachment
    @attachment ||= section.find_attachment_by_id(attachment_id)
  end

  def section
    @section ||= manual.sections.find { |s| s.id == section_id }
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def manual_id
    context.params.fetch("manual_id")
  end

  def section_id
    context.params.fetch("section_id")
  end

  def attachment_id
    context.params.fetch("id")
  end
end
