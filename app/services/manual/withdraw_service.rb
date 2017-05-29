require "adapters"

class Manual::WithdrawService
  def initialize(user:, manual_id:)
    @user = user
    @manual_id = manual_id
  end

  def call
    manual.withdraw

    if manual.withdrawn?
      manual.save(user)
      withdraw_via_publishing_api
      remove_from_search_index
    end

    manual
  end

private

  attr_reader :user, :manual_id

  def withdraw_via_publishing_api
    Adapters.publishing.unpublish(manual)
  end

  def remove_from_search_index
    Adapters.search_index.remove(manual)
  end

  def manual
    @manual ||= Manual.find(manual_id, user)
  rescue KeyError => error
    raise ManualNotFoundError.new(error)
  end

  class ManualNotFoundError < StandardError; end
end
