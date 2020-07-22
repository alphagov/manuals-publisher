require "adapters"

class Section::CreateService
  def initialize(user:, manual_id:, attributes:)
    @user = user
    @manual_id = manual_id
    @attributes = attributes
  end

  def call
    manual = Manual.find(manual_id, user)
    new_section = manual.build_section(attributes)

    if new_section.valid?
      manual.draft
      Adapters.publishing.save_draft(manual, include_sections: false)
      Adapters.publishing.save_section(new_section, manual)
      manual.save!(user)
    end

    [manual, new_section]
  end

private

  attr_reader :user, :manual_id, :attributes
end
