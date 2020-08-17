require "adapters"

class Section::UpdateService
  def initialize(user:, manual_id:, section_uuid:, attributes:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attributes = attributes
  end

  def call
    manual = Manual.find(manual_id, user)
    section = manual.find_section(section_uuid)
    section.assign_attributes(attributes)

    if section.valid?
      manual.draft
      Adapters.publishing.save_draft(manual, include_sections: false)
      Adapters.publishing.save_section(section, manual)
      manual.save!(user)
    end

    [manual, section]
  end

private

  attr_reader :user, :manual_id, :section_uuid, :attributes
end
