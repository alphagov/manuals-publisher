require "logger"
require "thor"

def shell
  @shell ||= Thor::Shell::Basic.new
end

desc "Republish manuals"
task :republish_manuals, %i[user_email slug] => :environment do |_, args|
  logger = Logger.new($stdout)
  logger.formatter = Logger::Formatter.new

  user = User.find_by(email: args[:user_email])

  manuals = if args.key?(:slug)
              [Manual.find_by_slug!(args[:slug], user)]
            else
              Manual.all(user)
            end

  republisher = ManualsRepublisher.new(logger)
  unless shell.yes?("Proceed with republishing manuals for user #{args[:user_email]} (yes/no)")
    shell.say_error "Aborted"
    next
  end
  republisher.execute(manuals)
end
