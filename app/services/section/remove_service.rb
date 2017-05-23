require "adapters"

class Section::RemoveService
  def initialize(user:, manual_id:, section_uuid:, attributes:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attributes = attributes
  end

  def call
    section = manual.sections.find { |s| s.uuid == section_uuid }
    raise SectionNotFoundError.new(section_uuid) unless section.present?

    section.update(change_note_params)

    if section.valid?
      # Removing a section always makes the manual a draft
      manual.draft

      manual.remove_section(section_uuid)
      manual.save(user)
      export_draft_manual_to_publishing_api
      discard_section_via_publishing_api
    end

    [manual, section]
  end

private

  attr_reader :user, :manual_id, :section_uuid, :attributes

  def manual
    @manual ||= Manual.find(manual_id, user)
  rescue KeyError
    raise ManualNotFoundError.new(manual_id)
  end

  def change_note_params
    {
      minor_update: attributes.fetch(:minor_update, "0"),
      change_note: attributes.fetch(:change_note, ""),
    }
  end

  def discard_section_via_publishing_api
    Adapters.publishing.discard_section(section)
  end

  def export_draft_manual_to_publishing_api
    Adapters.publishing.save(manual, include_sections: false)
  end

  class ManualNotFoundError < StandardError; end
  class SectionNotFoundError < StandardError; end
end
