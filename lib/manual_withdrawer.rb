require "manual_service_registry"

class ManualWithdrawer
  attr_reader :logger

  def initialize(logger)
    @logger = logger
  end

  def execute(manual_id)
    manual = ManualServiceRegistry.new.withdraw(manual_id).call

    if manual.withdrawn?
      logger.info "SUCCESS: Manual `#{manual.slug}` withdrawn"
    else
      message = "Manual `#{manual.slug}` could not be withdrawn"
      logger.error "FAILURE: #{message}"
      raise message
    end
  rescue WithdrawManualService::ManualNotFoundError
    message = "Manual not found for manual_id `#{manual_id}`"
    STDERR.puts "ERROR: #{message}"
    raise message
  end
end
