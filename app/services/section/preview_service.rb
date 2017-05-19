class Section::PreviewService
  def initialize(user:, attributes:, section_uuid:, manual_id:)
    @user = user
    @attributes = attributes
    @section_uuid = section_uuid
    @manual_id = manual_id
  end

  def call
    section.update(attributes)

    SectionPresenter.new(section)
  end

private

  attr_reader :user, :attributes, :section_uuid, :manual_id

  def section
    section_uuid ? existing_section : ephemeral_section
  end

  def manual
    Manual.find(manual_id, user)
  end

  def ephemeral_section
    manual.build_section(attributes)
  end

  def existing_section
    @existing_section ||= manual.sections.find { |section|
      section.uuid == section_uuid
    }
  end
end
