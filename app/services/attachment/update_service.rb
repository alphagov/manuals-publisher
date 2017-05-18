class Attachment::UpdateService
  def initialize(context:, file:, title:)
    @context = context
    @file = file
    @title = title
  end

  def call
    attachment.update_attributes(file: file, title: title, filename: file.original_filename)

    manual.save(context.current_user)

    [manual, section, attachment]
  end

private

  attr_reader :context, :file, :title

  def attachment
    @attachment ||= section.find_attachment_by_id(attachment_id)
  end

  def section
    @section ||= manual.sections.find { |s| s.uuid == section_uuid }
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def manual_id
    context.params.fetch("manual_id")
  end

  def section_uuid
    context.params.fetch("section_id")
  end

  def attachment_id
    context.params.fetch("id")
  end
end
