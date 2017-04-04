class NewSectionAttachmentService
  def initialize(context:)
    @builder = Attachment.method(:new)
    @context = context
  end

  def call
    [manual, section, attachment]
  end

private

  attr_reader :builder, :context

  def attachment
    builder.call(initial_params)
  end

  def section
    @section ||= manual.sections.find { |s| s.id == section_id }
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def initial_params
    {}
  end

  def manual_id
    context.params.fetch("manual_id")
  end

  def section_id
    context.params.fetch("section_id")
  end
end
