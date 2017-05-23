class Section::NewService
  def initialize(user:, manual_id:)
    @user = user
    @manual_id = manual_id
  end

  def call
    manual = Manual.find(manual_id, user)
    [manual, manual.build_section({})]
  end

private

  attr_reader :user, :manual_id
end
