class Section::PreviewService
  def initialize(user:, section_params:, section_uuid:, manual_id:)
    @user = user
    @section_params = section_params
    @section_uuid = section_uuid
    @manual_id = manual_id
  end

  def call
    section.update(section_params)

    SectionPresenter.new(section)
  end

private

  attr_reader :user, :section_params, :section_uuid, :manual_id

  def section
    section_uuid ? existing_section : ephemeral_section
  end

  def manual
    Manual.find(manual_id, user)
  end

  def ephemeral_section
    manual.build_section(section_params)
  end

  def existing_section
    @existing_section ||= manual.sections.find { |section|
      section.uuid == section_uuid
    }
  end
end
