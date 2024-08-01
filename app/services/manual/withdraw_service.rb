class Manual::WithdrawService
  def initialize(user:, manual_id:)
    @user = user
    @manual_id = manual_id
  end

  def call
    manual = Manual.find(manual_id, user)
    manual.withdraw

    if manual.withdrawn?
      manual.save!(user)
      Publishing::UnpublishAdapter.unpublish_manual_and_sections_as_gone(manual)
    end

    manual
  end

private

  attr_reader :user, :manual_id
end
