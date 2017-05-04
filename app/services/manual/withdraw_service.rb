require "adapters"

class Manual::WithdrawService
  def initialize(manual_id:, context:)
    @manual_id = manual_id
    @context = context
  end

  def call
    withdraw

    if manual.withdrawn?
      persist
      withdraw_via_publishing_api
      remove_from_search_index
    end

    manual
  end

private

  attr_reader :manual_id, :context

  def withdraw
    manual.withdraw
  end

  def persist
    manual.save(context.current_user)
  end

  def withdraw_via_publishing_api
    PublishingApiManualWithSectionsWithdrawer.new.call(manual)
  end

  def remove_from_search_index
    Adapters.search_index.remove(manual)
  end

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  rescue KeyError => error
    raise ManualNotFoundError.new(error)
  end

  class ManualNotFoundError < StandardError; end
end
