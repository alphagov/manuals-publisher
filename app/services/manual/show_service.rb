class Manual::ShowService
  def initialize(manual_id:, user:)
    @manual_id = manual_id
    @user = user
  end

  def call
    manual
  end

private

  attr_reader(
    :manual_id,
    :user,
  )

  def manual
    @manual ||= Manual.find(manual_id, user)
  end
end
