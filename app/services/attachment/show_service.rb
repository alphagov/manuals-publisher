class Attachment::ShowService
  def initialize(user:, attachment_id:, manual_id:, section_uuid:)
    @user = user
    @attachment_id = attachment_id
    @manual_id = manual_id
    @section_uuid = section_uuid
  end

  def call
    [manual, section, attachment]
  end

private

  attr_reader :user, :attachment_id, :manual_id, :section_uuid

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
