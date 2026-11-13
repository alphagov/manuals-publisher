require "logger"

desc "Republish all manuals"
task republish_all_manuals: :environment do
  logger = Logger.new($stdout)
  logger.formatter = Logger::Formatter.new

  manual_records = ManualRecord.all.reject { |mr| mr.latest_edition.state == "withdrawn" }
  manuals = manual_records.map { |mr| Manual.build_manual_for(mr) }

  republisher = ManualsRepublisher.new(logger)
  republisher.execute(manuals)
end
