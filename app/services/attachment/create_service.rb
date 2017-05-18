class Attachment::CreateService
  def initialize(file:, title:, section_uuid:, user:, manual_id:)
    @file = file
    @title = title
    @section_uuid = section_uuid
    @user = user
    @manual_id = manual_id
  end

  def call
    attachment = section.add_attachment(file: file, title: title)

    manual.save(user)

    [manual, section, attachment]
  end

private

  attr_reader :file, :title, :section_uuid, :user, :manual_id

  def section
    @section ||= manual.sections.find { |s| s.uuid == section_uuid }
  end

  def manual
    @manual ||= Manual.find(manual_id, user)
  end
end
