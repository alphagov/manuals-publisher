require "manual_publication_log_filter"
require "logger"

desc "Rebuild major publication logs for manuals"
task :rebuild_major_publication_logs_for_manuals, [:slug] => :environment do |_, args|
  logger = Logger.new(STDOUT)
  logger.formatter = Logger::Formatter.new

  manual_records = if args.has_key?(:slug)
                     ManualRecord.where(slug: args[:slug])
                   else
                     ManualRecord.all
                   end

  count = manual_records.count

  logger.info "Deleting publication logs and rebuilding for major updates only for #{count} manuals"

  manual_records.to_a.each.with_index(1) do |manual, i|
    manual_publication_log_filter = ManualPublicationLogFilter.new(manual)
    logger.info("[% 3d/% 3d] id=%s slug=%s" % [i, count, manual.id, manual.slug])
    manual_publication_log_filter.delete_logs_and_rebuild_for_major_updates_only!
  end

  logger.info "Rebuilding of publication logs complete."
end
