require "logger"

desc "Withdraw a manual"
task :withdraw_manual, %i[manual_id redirect_path] => :environment do |_, args|
  logger = Logger.new($stdout)
  logger.formatter = Logger::Formatter.new

  manual_id = args.fetch(:manual_id)

  withdrawer = ManualWithdrawer.new(logger)
  withdrawer.execute(manual_id, redirect_path: nil)
end
