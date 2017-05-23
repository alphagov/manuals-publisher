require "adapters"

class Section::UpdateService
  def initialize(user:, manual_id:, section_uuid:, attributes:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attributes = attributes
  end

  def call
    section.update(attributes)

    if section.valid?
      manual.draft
      manual.save(user)
      export_draft_manual_to_publishing_api
      Adapters.publishing.save_section(section, manual)
    end

    [manual, section]
  end

private

  attr_reader :user, :manual_id, :section_uuid, :attributes, :listeners

  def section
    @section ||= manual.sections.find { |s| s.uuid == section_uuid }
  end

  def manual
    @manual ||= Manual.find(manual_id, user)
  end

  def export_draft_manual_to_publishing_api
    Adapters.publishing.save(manual, include_sections: false)
  end
end
