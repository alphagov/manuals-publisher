class Section::PreviewService
  def initialize(user:, manual_id:, section_uuid:, attributes:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attributes = attributes
  end

  def call
    section = if section_uuid
                existing_section
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

  def existing_section
    @existing_section ||= manual.sections.find { |section|
      section.uuid == section_uuid
    }
  end
end
