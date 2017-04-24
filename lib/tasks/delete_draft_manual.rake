require "cli_manual_deleter"

desc "Delete draft manual"
task :delete_draft_manual, [:manual_slug, :manual_id] => :environment do |_, args|
  manual_slug = args.fetch(:manual_slug)
  manual_id = args.fetch(:manual_id)
  CliManualDeleter.new(manual_slug, manual_id: manual_id).call
end
