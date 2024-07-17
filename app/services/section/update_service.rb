class Section::UpdateService
  def initialize(user:, manual_id:, section_uuid:, attributes:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attributes = attributes
  end

  def call
    manual = Manual.find(manual_id, user)
    section = manual.find_section(section_uuid)
    section.assign_attributes(attributes.merge(
                                last_updated_by: user.name,
                                slug: SlugGenerator.new(prefix: manual.slug).call(attributes.fetch(:title)),
                              ))

    if section.valid?
      manual.draft
      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, include_sections: false)
      PublishingAdapter.save_section(section, manual)
      manual.save!(user)
    end

    [manual, section]
  end

private

  attr_reader :user, :manual_id, :section_uuid, :attributes
end
