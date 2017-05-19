class Attachment::NewService
  def initialize(manual_id:, section_uuid:, user:)
    @manual_id = manual_id
    @section_uuid = section_uuid
    @user = user
  end

  def call
    [manual, section, attachment]
  end

private

  attr_reader :manual_id, :section_uuid, :user

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
