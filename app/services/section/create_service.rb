require "adapters"

class Section::CreateService
  def initialize(context:)
    @context = context
  end

  def call
    @new_section = manual.build_section(section_params)

    if new_section.valid?
      manual.draft
      manual.save(context.current_user)
      export_draft_manual_to_publishing_api
      export_draft_section_to_publishing_api
    end

    [manual, new_section]
  end

private

  attr_reader :context

  attr_reader :new_section

  def manual
    @manual ||= Manual.find(context.params.fetch("manual_id"), context.current_user)
  end

  def export_draft_manual_to_publishing_api
    Adapters.publishing.save(manual, include_sections: false)
  end

  def export_draft_section_to_publishing_api
    Adapters.publishing.save_section(new_section, manual)
  end

  def section_params
    context.params.fetch("section")
  end
end
