class Section::ShowService
  def initialize(user:, manual_id:, section_uuid:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
  end

  def call
    manual = Manual.find(manual_id, user)
    section = manual.find_section(section_uuid)
    [manual, section]
  end

private

  attr_reader :user, :manual_id, :section_uuid
end
