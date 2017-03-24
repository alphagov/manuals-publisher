class CreateSectionAttachmentService
  def initialize(manual_repository, context)
    @manual_repository = manual_repository
    @context = context
  end

  def call
    attachment = section.add_attachment(attachment_params)

    manual_repository.store(manual)

    [manual, section, attachment]
  end

private

  attr_reader :manual_repository, :context

  def section
    @section ||= manual.sections.find { |s| s.id == section_id }
  end

  def manual
    @manual ||= manual_repository.fetch(manual_id)
  end

  def attachment_params
    context.params.fetch("attachment")
  end

  def manual_id
    context.params.fetch("manual_id")
  end

  def section_id
    context.params.fetch("section_id")
  end
end
