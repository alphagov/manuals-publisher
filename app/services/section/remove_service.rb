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

    # We need to capture the state of the section before assigning attributes.
    # The Section#assign_attributes method always creates a new draft section if
    # the latest edition is published.
    # This causes PublishingAdapter.discard_section(section) to be called which
    # blows up as there is no draft section in the Publishing API database.
    draft_section = section.draft?

    section.assign_attributes(change_note_params)

    if section.valid?
      # Removing a section always makes the manual a draft
      manual.draft

      manual.remove_section(section_uuid)
      manual.save!(user)
      PublishingAdapter.save_draft(manual, include_sections: false)

      if draft_section
        PublishingAdapter.discard_section(section)
      end
    end

    [manual, section]
  end

private

  attr_reader :user, :manual_id, :section_uuid, :attributes

  class ManualNotFoundError < StandardError; end

  class SectionNotFoundError < StandardError; end
end
