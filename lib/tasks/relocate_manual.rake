require "manual_relocator"
require "logger"

desc <<-EndDesc
Relocate manual from <from-slug> to <to-slug>
Both <from-slug> and <to-slug> need to be published manuals
EndDesc
task :relocate_manual, [:from_slug, :to_slug] => :environment do |_, args|
  ManualRelocator.move(args[:from_slug], args[:to_slug])
end
