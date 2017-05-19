require "adapters"

class Section::UpdateService
  def initialize(user:, section_uuid:, manual_id:, attributes:)
    @user = user
    @section_uuid = section_uuid
    @manual_id = manual_id
    @attributes = attributes
  end

  def call
    section.update(attributes)

    if section.valid?
      manual.draft
      manual.save(user)
      export_draft_manual_to_publishing_api
      export_draft_section_to_publishing_api
    end

    [manual, section]
  end

private

  attr_reader :user, :section_uuid, :manual_id, :attributes, :listeners

  def section
    @section ||= manual.sections.find { |s| s.uuid == section_uuid }
  end

  def manual
    @manual ||= Manual.find(manual_id, user)
  end

  def export_draft_manual_to_publishing_api
    Adapters.publishing.save(manual, include_sections: false)
  end

  def export_draft_section_to_publishing_api
    Adapters.publishing.save_section(section, manual)
  end
end
