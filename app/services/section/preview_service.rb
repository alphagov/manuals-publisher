class Section::PreviewService
  def initialize(user:, manual_id:, section_uuid:, attributes:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attributes = attributes
  end

  def call
    section = if section_uuid
                manual.sections.find { |sec|
                  sec.uuid == section_uuid
                }
              else
                manual.build_section(attributes)
              end
    section.update(attributes)

    SectionPresenter.new(section)
  end

private

  attr_reader :user, :manual_id, :section_uuid, :attributes

  def manual
    Manual.find(manual_id, user)
  end
end
