class Attachment::UpdateService
  def initialize(user:, attachment_id:, manual_id:, section_uuid:, attributes:)
    @user = user
    @attachment_id = attachment_id
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attributes = attributes
  end

  def call
    manual = Manual.find(manual_id, user)
    section = manual.find_section(section_uuid)
    attachment = section.find_attachment_by_id(attachment_id)
    attachment.update!(attributes.merge(filename: attributes[:file].original_filename))

    manual.save!(user)

    [manual, section, attachment]
  end

private

  attr_reader :user, :attachment_id, :manual_id, :section_uuid, :attributes
end
