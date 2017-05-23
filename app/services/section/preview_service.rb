class Section::PreviewService
  def initialize(user:, manual_id:, section_uuid:, attributes:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
    @attributes = attributes
  end

  def call
    section.update(attributes)

    SectionPresenter.new(section)
  end

private

  attr_reader :user, :manual_id, :section_uuid, :attributes

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
