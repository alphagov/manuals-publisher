require "logger"

desc <<~DESCRIPTION
  Relocate manual from <from-slug> to <to-slug>
  Both <from-slug> and <to-slug> need to be published manuals
DESCRIPTION
task :relocate_manual, %i[from_slug to_slug] => :environment do |_, args|
  puts "You're about to relocate manual from #{args[:from_slug]} to #{args[:to_slug]}"
  unless Thor::Shell::Basic.new.yes?("Would you like to proceed with this relocation? (yes/no)")
    puts "Aborted"
    exit 1
  end

  ManualRelocator.move(args[:from_slug], args[:to_slug])
end
