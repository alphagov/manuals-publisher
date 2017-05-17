class Attachment::UpdateService
  def initialize(context:)
    @context = context
  end

  def call
    attachment.update_attributes(attachment_params)

    manual.save(context.current_user)

    [manual, section, attachment]
  end

private

  attr_reader :context

  def attachment
    @attachment ||= section.find_attachment_by_id(attachment_id)
  end

  def section
    @section ||= manual.sections.find { |s| s.uuid == section_uuid }
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def attachment_params
    context.params
      .require("attachment")
      .permit(:title, :file)
      .merge("filename" => uploaded_filename)
  end

  def uploaded_filename
    context.params
      .require("attachment")
      .fetch(:file)
      .original_filename
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
