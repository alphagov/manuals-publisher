namespace :sections do
  desc "Identifies manual sections which do not match the section title."
  task :report, [:manual_slug] => :environment do |_, args|
    SectionSlugSynchroniser.new(args[:manual_slug]).report
  end

  desc "Synchronises manual section slugs with their titles."
  task :synchronise, [:manual_slug] => :environment do |_, args|
    SectionSlugSynchroniser.new(args[:manual_slug]).synchronise
  end
end
