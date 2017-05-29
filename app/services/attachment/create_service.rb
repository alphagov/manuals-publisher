class Attachment::CreateService
  def initialize(user:, manual_id:, section_uuid:, attributes:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attributes = attributes
  end

  def call
    section = manual.find_section(section_uuid)
    attachment = section.add_attachment(attributes)

    manual.save(user)

    [manual, section, attachment]
  end

private

  attr_reader :user, :manual_id, :section_uuid, :attributes

  def manual
    @manual ||= Manual.find(manual_id, user)
  end
end
