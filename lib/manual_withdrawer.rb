class ManualWithdrawer
  attr_reader :logger

  def initialize(logger)
    @logger = logger
  end

  def execute(manual_id)
    service = Manual::WithdrawService.new(
      manual_id: manual_id,
      user: User.gds_editor,
    )
    manual = service.call

    if manual.withdrawn?
      logger.info "SUCCESS: Manual `#{manual.slug}` withdrawn"
    else
      message = "Manual `#{manual.slug}` could not be withdrawn"
      logger.error "FAILURE: #{message}"
      raise message
    end
  rescue Manual::WithdrawService::ManualNotFoundError
    message = "Manual not found for manual_id `#{manual_id}`"
    STDERR.puts "ERROR: #{message}"
    raise message
  end
end
