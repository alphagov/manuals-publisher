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
    section = manual.sections.find { |s| s.uuid == section_uuid }
    section.update(attributes)

    if section.valid?
      manual.draft
      manual.save(user)
      Adapters.publishing.save(manual, include_sections: false)
      Adapters.publishing.save_section(section, manual)
    end

    [manual, section]
  end

private

  attr_reader :user, :manual_id, :section_uuid, :attributes
end
