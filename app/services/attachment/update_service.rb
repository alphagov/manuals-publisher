class Attachment::UpdateService
  def initialize(attributes:, user:, manual_id:, section_uuid:, attachment_id:)
    @user = user
    @attributes = attributes
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attachment_id = attachment_id
  end

  def call
    attachment.update_attributes(attributes.merge(filename: attributes[:file].original_filename))

    manual.save(user)

    [manual, section, attachment]
  end

private

  attr_reader :user, :attributes, :manual_id, :section_uuid, :attachment_id

  def attachment
    @attachment ||= section.find_attachment_by_id(attachment_id)
  end

  def section
    @section ||= manual.sections.find { |s| s.uuid == section_uuid }
  end

  def manual
    @manual ||= Manual.find(manual_id, user)
  end
end
