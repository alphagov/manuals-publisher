require "adapters"

class Section::CreateService
  def initialize(user:, manual_id:, attributes:)
    @user = user
    @manual_id = manual_id
    @attributes = attributes
  end

  def call
    manual = Manual.find(manual_id, user)
    @new_section = manual.build_section(attributes)

    if new_section.valid?
      manual.draft
      manual.save(user)
      export_draft_manual_to_publishing_api
      export_draft_section_to_publishing_api
    end

    [manual, new_section]
  end

private

  attr_reader :user, :manual_id, :attributes

  attr_reader :new_section

  def export_draft_manual_to_publishing_api
    Adapters.publishing.save(manual, include_sections: false)
  end

  def export_draft_section_to_publishing_api
    Adapters.publishing.save_section(new_section, manual)
  end
end
