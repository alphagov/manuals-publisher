require "thor"

desc <<~DESCRIPTION
  Change the slug of a manual (and its sections) from <old_slug> to <new_slug>.
  The old URLs are redirected to the new ones by the Publishing API.
  Example: rake "reslug_manual[guidance/old-manual,guidance/new-manual]"
DESCRIPTION
task :reslug_manual, %i[old_slug new_slug] => :environment do |_, args|
  puts "You're about to reslug a manual (and all its sections):"
  puts "  from: #{args[:old_slug]}"
  puts "  to:   #{args[:new_slug]}"

  unless Thor::Shell::Basic.new.yes?("Would you like to proceed with this reslug? (yes/no)")
    puts "Aborted"
    next
  end

  ManualReslugger.new(args[:old_slug], args[:new_slug]).call
  puts "Manual reslugged from '#{args[:old_slug]}' to '#{args[:new_slug]}' and republished."
end
