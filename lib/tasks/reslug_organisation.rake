require "thor"

def shell
  @shell ||= Thor::Shell::Basic.new
end

desc "Republish manuals"
task :reslug_organisation, %i[old_slug new_slug] => :environment do |_, args|
  unless args[:old_slug] && args[:new_slug] && args.count == 2
    raise "Invalid parameters provided to `reslug_organisation` Usage: reslug_organisation[old-slug,new-slug]."
  end

  manual_records = ManualRecord.where(organisation_slug: args[:old_slug]).to_a
  puts "Updating the `organisation_slug` of #{manual_records.count} manual records from '#{args[:old_slug]}' to '#{args[:new_slug]}'"
  unless shell.yes?("Would you like to proceed with this? (yes/no)")
    puts "Aborted"
    next
  end
  manual_records.each do |manual_record|
    puts "- Updating ManualRecord #{manual_record[:manual_id]} (#{manual_record[:slug]})"
    manual_record.update!(organisation_slug: args[:new_slug])
  end
  puts "Done."
end
