class Section::ShowService
  def initialize(user:, section_uuid:, manual_id:)
    @user = user
    @section_uuid = section_uuid
    @manual_id = manual_id
  end

  def call
    [manual, section]
  end

private

  attr_reader :user, :section_uuid, :manual_id

  def section
    @section ||= manual.sections.find { |s| s.uuid == section_uuid }
  end

  def manual
    @manual ||= Manual.find(manual_id, user)
  end
end
