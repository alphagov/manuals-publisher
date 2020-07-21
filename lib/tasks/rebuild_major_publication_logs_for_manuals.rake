require "logger"

desc "Rebuild major publication logs for manuals"
task :rebuild_major_publication_logs_for_manuals, [:slug] => :environment do |_, args|
  logger = Logger.new(STDOUT)
  logger.formatter = Logger::Formatter.new

  manuals = if args.key?(:slug)
              [Manual.find_by_slug!(args[:slug], user)]
            else
              Manual.all(user)
            end

  count = manual.count

  logger.info "Deleting publication logs and rebuilding for major updates only for #{count} manuals"

  manuals.each.with_index(1) do |manual, i|
    manual_publication_log_filter = ManualPublicationLogFilter.new(manual)
    logger.info(sprintf("[% 3d/% 3d] id=%s slug=%s", i, count, manual.id, manual.slug))
    manual_publication_log_filter.delete_logs_and_rebuild_for_major_updates_only!
  end

  logger.info "Rebuilding of publication logs complete."
end
