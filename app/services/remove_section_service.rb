class RemoveSectionService
  def initialize(context:)
    @context = context
  end

  def call
    raise SectionNotFoundError.new(section_id) unless section.present?

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

  attr_reader :context

  def remove
    manual.remove_section(section_id)
  end

  def persist
    manual.save(context.current_user)
  end

  def section
    @section ||= manual.sections.find { |s| s.id == section_id }
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  rescue KeyError
    raise ManualNotFoundError.new(manual_id)
  end

  def section_id
    context.params.fetch("id")
  end

  def manual_id
    context.params.fetch("manual_id")
  end

  def change_note_params
    section_params = context.params.fetch("section")
    {
      "minor_update" => section_params.fetch("minor_update", "0"),
      "change_note" => section_params.fetch("change_note", ""),
    }
  end

  def discard_section_via_publishing_api
    PublishingApiDraftSectionDiscarder.new.call(section, manual)
  end

  def export_draft_manual_to_publishing_api
    PublishingApiDraftManualExporter.new.call(manual)
  end

  class ManualNotFoundError < StandardError; end
  class SectionNotFoundError < StandardError; end
end
