class LinkCheckReport::FindReportableService
  def initialize(user:, manual_id:, section_id: nil)
    @user = user
    @manual_id = manual_id
    @section_id = section_id
  end

  def call
    if is_for_section?
      section
    else
      manual
    end
  end

private

  attr_reader :user, :manual_id, :section_id

  def manual
    @manual ||= Manual.find(manual_id, user)
  end

  def section
    raise "Not a section" unless is_for_section?

    @section ||= Section.find(manual, section_id)
  end

  def is_for_section?
    section_id.present?
  end
end
