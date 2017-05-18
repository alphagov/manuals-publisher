require "adapters"

class Section::CreateService
  def initialize(user:, manual_id:, section_params:)
    @user = user
    @manual_id = manual_id
    @section_params = section_params
  end

  def call
    @new_section = manual.build_section(section_params)

    if new_section.valid?
      manual.draft
      manual.save(user)
      export_draft_manual_to_publishing_api
      export_draft_section_to_publishing_api
    end

    [manual, new_section]
  end

private

  attr_reader :user, :manual_id, :section_params

  attr_reader :new_section

  def manual
    @manual ||= Manual.find(manual_id, user)
  end

  def export_draft_manual_to_publishing_api
    Adapters.publishing.save(manual, include_sections: false)
  end

  def export_draft_section_to_publishing_api
    Adapters.publishing.save_section(new_section, manual)
  end
end
