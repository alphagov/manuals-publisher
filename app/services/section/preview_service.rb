class Section::PreviewService
  def initialize(user:, manual_id:, section_uuid:, attributes:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attributes = attributes
  end

  def call
    manual = Manual.find(manual_id, user)
    section = if section_uuid
                manual.find_section(section_uuid)
              else
                manual.build_section(attributes)
              end
    section.assign_attributes(attributes)
    section
  end

private

  attr_reader :user, :manual_id, :section_uuid, :attributes
end
