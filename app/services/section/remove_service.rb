require "adapters"

class Section::RemoveService
  def initialize(user:, manual_id:, section_uuid:, attributes:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attributes = attributes
  end

  def call
    begin
      manual = Manual.find(manual_id, user)
    rescue KeyError
      raise ManualNotFoundError, manual_id
    end

    section = manual.find_section(section_uuid)
    raise SectionNotFoundError, section_uuid if section.blank?

    change_note_params = {
      minor_update: attributes.fetch(:minor_update, "0"),
      change_note: attributes.fetch(:change_note, ""),
    }
    section.update(change_note_params)

    if section.valid?
      # Removing a section always makes the manual a draft
      manual.draft

      manual.remove_section(section_uuid)
      manual.save(user)
      Adapters.publishing.save(manual, include_sections: false)
      Adapters.publishing.discard_section(section)
    end

    [manual, section]
  end

private

  attr_reader :user, :manual_id, :section_uuid, :attributes

  class ManualNotFoundError < StandardError; end
  class SectionNotFoundError < StandardError; end
end
