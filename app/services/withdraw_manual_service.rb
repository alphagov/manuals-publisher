class WithdrawManualService
  def initialize(manual_repository:, manual_id:)
    @manual_repository = manual_repository
    @manual_id = manual_id
  end

  def call
    withdraw

    if manual.withdrawn?
      persist
      withdraw_via_publishing_api
      withdraw_from_rummager
    end

    manual
  end

private

  attr_reader :manual_repository, :manual_id

  def withdraw
    manual.withdraw
  end

  def persist
    manual_repository.store(manual)
  end

  def withdraw_via_publishing_api
    PublishingApiManualWithSectionsWithdrawer.new.call(manual)
  end

  def withdraw_from_rummager
    RummagerManualWithSectionsWithdrawer.new.call(manual)
  end

  def manual
    @manual ||= manual_repository.fetch(manual_id)
  rescue KeyError => error
    raise ManualNotFoundError.new(error)
  end

  class ManualNotFoundError < StandardError; end
end
