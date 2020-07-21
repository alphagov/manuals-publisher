desc "Delete draft manual (supply EITHER manual_slug OR manual_id)"
task :delete_draft_manual, %i[manual_slug manual_id] => :environment do |_, args|
  CliManualDeleter.new(manual_slug: args[:manual_slug], manual_id: args[:manual_id]).call
end
