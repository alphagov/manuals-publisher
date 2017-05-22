require "manuals_republisher"
require "logger"

desc "Republish manuals"
task :republish_manuals, [:slug] => :environment do |_, args|
  logger = Logger.new(STDOUT)
  logger.formatter = Logger::Formatter.new

  manuals = if args.has_key?(:slug)
              [Manual.find_by_slug!(args[:slug], user)]
            else
              Manual.all(user)
            end

  republisher = ManualsRepublisher.new(logger)
  republisher.execute(manuals)
end
