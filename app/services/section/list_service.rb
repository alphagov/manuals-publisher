class Section::ListService
  def initialize(user:, manual_id:)
    @user = user
    @manual_id = manual_id
  end

  def call
    [manual, sections]
  end

private

  attr_reader :user, :manual_id

  def sections
    manual.sections
  end

  def manual
    @manual ||= Manual.find(manual_id, user)
  end
end
