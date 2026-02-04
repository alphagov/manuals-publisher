require "logger"
require "thor"

def shell
  @shell ||= Thor::Shell::Basic.new
end

desc "Republish all manuals"
task republish_all_manuals: :environment do
  logger = Logger.new($stdout)
  logger.formatter = Logger::Formatter.new

  manual_records = ManualRecord.all.reject { |mr| mr.latest_edition.state == "withdrawn" }
  manuals = manual_records.map { |mr| Manual.build_manual_for(mr) }

  republisher = ManualsRepublisher.new(logger)
  unless shell.yes?("Proceed with republishing all manuals (yes/no)")
    shell.say_error "Aborted"
    next
  end
  republisher.execute(manuals)
end
