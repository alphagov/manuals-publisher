require "logger"

desc "Withdraw a manual"
task :withdraw_manual, [:manual_id] => :environment do |_, args|
  logger = Logger.new(STDOUT)
  logger.formatter = Logger::Formatter.new

  manual_id = args.fetch(:manual_id)

  withdrawer = ManualWithdrawer.new(logger)
  withdrawer.execute(manual_id)
end
