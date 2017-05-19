require "adapters"

class Section::RemoveService
  def initialize(user:, section_uuid:, manual_id:, section_params:)
    @user = user
    @section_uuid = section_uuid
    @manual_id = manual_id
    @section_params = section_params
  end

  def call
    raise SectionNotFoundError.new(section_uuid) unless section.present?

    section.update(change_note_params)

    if section.valid?
      # Removing a section always makes the manual a draft
      manual.draft

      remove
      persist
      export_draft_manual_to_publishing_api
      discard_section_via_publishing_api
    end

    [manual, section]
  end

private

  attr_reader :user, :section_uuid, :manual_id, :section_params

  def remove
    manual.remove_section(section_uuid)
  end

  def persist
    manual.save(user)
  end

  def section
    @section ||= manual.sections.find { |s| s.uuid == section_uuid }
  end

  def manual
    @manual ||= Manual.find(manual_id, user)
  rescue KeyError
    raise ManualNotFoundError.new(manual_id)
  end

  def change_note_params
    {
      "minor_update" => section_params.fetch("minor_update", "0"),
      "change_note" => section_params.fetch("change_note", ""),
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
