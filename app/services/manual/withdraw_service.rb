require "adapters"

class Manual::WithdrawService
  def initialize(user:, manual_id:, redirect_path: nil)
    @user = user
    @manual_id = manual_id
    @redirect_path = redirect_path
  end

  def call
    begin
      manual = Manual.find(manual_id, user)
    rescue KeyError => e
      raise ManualNotFoundError, e
    end

    manual.withdraw

    if manual.withdrawn?
      manual.save!(user)
      Adapters.publishing.unpublish(manual, @redirect_path)
    end

    manual
  end

private

  attr_reader :user, :manual_id

  class ManualNotFoundError < StandardError; end
end
