class ShowSectionAttachmentService
  def initialize(manual_repository:, context:)
    @manual_repository = manual_repository
    @context = context
  end

  def call
    [manual, section, attachment]
  end

private

  attr_reader :manual_repository, :context

  def attachment
    @attachment ||= section.find_attachment_by_id(attachment_id)
  end

  def section
    @section ||= manual.sections.find { |s| s.id == section_id }
  end

  def manual
    @manual ||= manual_repository.fetch(manual_id)
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
