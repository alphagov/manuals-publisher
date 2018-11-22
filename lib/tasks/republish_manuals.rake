require "manuals_republisher"
require "logger"

desc "Republish manuals"
task :republish_manuals, %i[user_email slug] => :environment do |_, args|
  logger = Logger.new(STDOUT)
  logger.formatter = Logger::Formatter.new

  user = User.find_by(email: args[:user_email])

  manuals = if args.has_key?(:slug)
              [Manual.find_by_slug!(args[:slug], user)]
            else
              Manual.all(user)
            end

  republisher = ManualsRepublisher.new(logger)
  republisher.execute(manuals)
end
