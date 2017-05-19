class Attachment::NewService
  def initialize(user:, manual_id:, section_uuid:)
    @user = user
    @manual_id = manual_id
    @section_uuid = section_uuid
  end

  def call
    [manual, section, attachment]
  end

private

  attr_reader :user, :manual_id, :section_uuid

  def attachment
    Attachment.new(initial_params)
  end

  def section
    @section ||= manual.sections.find { |s| s.uuid == section_uuid }
  end

  def manual
    @manual ||= Manual.find(manual_id, user)
  end

  def initial_params
    {}
  end
end
