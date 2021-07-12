class ManualRedirecter
  attr_reader :logger

  def initialize(logger)
    @logger = logger
  end

  def execute(manual_id, alternative_path)
    service = Manual::RedirectService.new(
      user: User.gds_editor,
      manual_id: manual_id,
      alternative_path: alternative_path,
    )
    manual = service.call

    if manual.removed?
      logger.info "SUCCESS: Manual `#{manual.slug}` redirected"
    else
      message = "Manual `#{manual.slug}` could not be redirected"
      logger.error "FAILURE: #{message}"
      raise message
    end
  rescue Manual::RedirectService::ManualNotFoundError
    message = "Manual not found for manual_id `#{manual_id}`"
    warn "ERROR: #{message}"
    raise message
  end
end
