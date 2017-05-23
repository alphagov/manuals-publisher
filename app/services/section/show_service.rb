class Section::ShowService
  def initialize(user:, manual_id:, section_uuid:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
  end

  def call
    section = manual.sections.find { |s| s.uuid == section_uuid }
    [manual, section]
  end

private

  attr_reader :user, :manual_id, :section_uuid

  def manual
    @manual ||= Manual.find(manual_id, user)
  end
end
