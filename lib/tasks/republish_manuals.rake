require "manuals_republisher"
require "logger"

desc "Republish manuals"
task republish_manuals: [:environment] do
  logger = Logger.new(STDOUT)
  logger.formatter = Logger::Formatter.new

  republisher = ManualsRepublisher.new(logger)
  republisher.execute
end
