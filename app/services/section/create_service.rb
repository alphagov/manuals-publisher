class Section::CreateService
  def initialize(user:, manual_id:, attributes:)
    @user = user
    @manual_id = manual_id
    @attributes = attributes
  end

  def call
    manual = Manual.find(manual_id, user)
    new_section = manual.build_section(attributes.merge(
                                         last_updated_by: user.name,
                                         slug: SlugGenerator.new(prefix: manual.slug).call(attributes.fetch(:title)),
                                       ))

    if new_section.valid?
      manual.draft
      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, include_sections: false)
      Publishing::DraftAdapter.save_draft_for_section(new_section, manual)
      manual.save!(user)
    end

    [manual, new_section]
  end

private

  attr_reader :user, :manual_id, :attributes
end
