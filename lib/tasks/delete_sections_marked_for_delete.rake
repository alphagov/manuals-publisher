desc "Delete sections marked for delete"
task delete_sections_marked_for_delete: :environment do
  MarkedSectionDeleter.new.execute
end
