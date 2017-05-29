class Manual::ShowService
  def initialize(user:, manual_id:)
    @user = user
    @manual_id = manual_id
  end

  def call
    Manual.find(manual_id, user)
  end

private

  attr_reader :user, :manual_id
end
