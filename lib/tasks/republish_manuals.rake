require "manuals_republisher"
require "logger"

desc "Republish manuals"
task :republish_manuals, [:slug] => :environment do |_, args|
  logger = Logger.new(STDOUT)
  logger.formatter = Logger::Formatter.new

  manual_records = if args.has_key?(:slug)
                     ManualRecord.where(slug: args[:slug])
                   else
                     ManualRecord.all
                   end

  republisher = ManualsRepublisher.new(logger)
  republisher.execute(manual_records)
end
