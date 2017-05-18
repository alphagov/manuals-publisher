class Attachment::UpdateService
  def initialize(context:, attachment_params:)
    @context = context
    @attachment_params = attachment_params
  end

  def call
    attachment.update_attributes(attachment_params.merge("filename" => uploaded_filename))

    manual.save(context.current_user)

    [manual, section, attachment]
  end

private

  attr_reader :context, :attachment_params

  def attachment
    @attachment ||= section.find_attachment_by_id(attachment_id)
  end

  def section
    @section ||= manual.sections.find { |s| s.uuid == section_uuid }
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def uploaded_filename
    attachment_params.fetch(:file).original_filename
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
