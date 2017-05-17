require "cli_manual_deleter"

desc "Delete draft manual"
task :delete_draft_manual, [:manual_slug, :manual_id] => :environment do |_, args|
  CliManualDeleter.new(args[:manual_slug], manual_id: args[:manual_id]).call
end
