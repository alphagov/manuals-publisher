require "logger"

desc <<~DESCRIPTION
  Relocate manual from <from-slug> to <to-slug>
  Both <from-slug> and <to-slug> need to be published manuals
DESCRIPTION
task :relocate_manual, %i[from_slug to_slug] => :environment do |_, args|
  puts "Relocating manual from #{args[:from_slug]} to #{args[:to_slug]}"
  ManualRelocator.move(args[:from_slug], args[:to_slug])
end
