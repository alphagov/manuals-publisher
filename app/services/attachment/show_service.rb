class Attachment::ShowService
  def initialize(user:, section_uuid:, manual_id:, attachment_id:)
    @user = user
    @section_uuid = section_uuid
    @manual_id = manual_id
    @attachment_id = attachment_id
  end

  def call
    [manual, section, attachment]
  end

private

  attr_reader :user, :section_uuid, :manual_id, :attachment_id

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
