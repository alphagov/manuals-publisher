class Attachment::ShowService
  def initialize(user:, attachment_id:, manual_id:, section_uuid:)
    @user = user
    @attachment_id = attachment_id
    @manual_id = manual_id
    @section_uuid = section_uuid
  end

  def call
    manual = Manual.find(manual_id, user)
    section = manual.find_section(section_uuid)
    attachment = section.find_attachment_by_id(attachment_id)

    [manual, section, attachment]
  end

private

  attr_reader :user, :attachment_id, :manual_id, :section_uuid
end
