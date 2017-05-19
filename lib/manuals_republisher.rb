class ManualsRepublisher
  attr_reader :logger

  def initialize(logger)
    @logger = logger
  end

  def execute(manual_records = ManualRecord.all)
    count = manual_records.count

    logger.info "Republishing #{count} manuals..."

    manual_records.to_a.each.with_index do |manual_record, i|
      begin
        logger.info("[ #{i} / #{count} ] id=#{manual_record.manual_id} slug=#{manual_record.slug}]")
        service = Manual::RepublishService.new(
          user: User.gds_editor,
          manual_id: manual_record.manual_id
        )
        service.call
      rescue Manual::RemovedSectionIdNotFoundError => e
        logger.error("Did not publish manual with id=#{manual_record.manual_id} slug=#{manual_record.slug}. It has at least one removed document which was not found: #{e.message}")
        next
      end
    end

    logger.info "Republishing of #{count} manuals complete."
  end
end
