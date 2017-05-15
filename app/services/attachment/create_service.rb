class Attachment::CreateService
  def initialize(context:)
    @context = context
  end

  def call
    attachment = section.add_attachment(attachment_params)

    manual.save(context.current_user)

    [manual, section, attachment]
  end

private

  attr_reader :context

  def section
    @section ||= manual.sections.find { |s| s.uuid == section_uuid }
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def attachment_params
    context.params.require("attachment").permit(:title, :file)
  end

  def manual_id
    context.params.fetch("manual_id")
  end

  def section_uuid
    context.params.fetch("section_id")
  end
end
