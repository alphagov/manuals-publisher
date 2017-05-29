require "adapters"

class Manual::WithdrawService
  def initialize(user:, manual_id:)
    @user = user
    @manual_id = manual_id
  end

  def call
    begin
      manual = Manual.find(manual_id, user)
    rescue KeyError => error
      raise ManualNotFoundError.new(error)
    end

    manual.withdraw

    if manual.withdrawn?
      manual.save(user)
      Adapters.publishing.unpublish(manual)
      Adapters.search_index.remove(manual)
    end

    manual
  end

private

  attr_reader :user, :manual_id

  class ManualNotFoundError < StandardError; end
end
