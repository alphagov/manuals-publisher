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
      Adapters.publishing.unpublish(manual)
      remove_from_search_index
    end

    manual
  end

private

  attr_reader :user, :manual_id

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
