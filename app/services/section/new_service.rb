class Section::NewService
  def initialize(user:, manual_id:)
    @user = user
    @manual_id = manual_id
  end

  def call
    [manual, manual.build_section({})]
  end

private

  attr_reader :user, :manual_id

  def manual
    @manual ||= Manual.find(manual_id, user)
  end
end
