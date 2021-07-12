require "logger"

desc "Redirect a manual"
task :redirect_manual, [:manual_id, :url] => :environment do |_, args|
  logger = Logger.new($stdout)
  logger.formatter = Logger::Formatter.new

  manual_id = args.fetch(:manual_id)

  redirecter = ManualRedirecter.new(logger)
  redirecter.execute(manual_id, url)
end
