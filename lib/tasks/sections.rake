require 'section_reslugger'
require 'section_slug_synchroniser'

namespace :sections do
  desc "Identifies manual sections which do not match the section title."
  task :report, [:manual_slug] => :environment do |_, args|
    SectionSlugSynchroniser.new(args[:manual_slug]).report
  end

  desc "Synchronises manual section slugs with their titles."
  task :synchronise, [:manual_slug] => :environment do |_, args|
    SectionSlugSynchroniser.new(args[:manual_slug]).synchronise
  end

  desc "Updates the section slug for a given manual."
  task :reslug_section, [:manual_slug, :current_section_slug, :new_section_slug] => :environment do |args|
    SectionReslugger.new(args[:manual_slug], args[:current_section_slug], args[:new_section_slug]).call
  end
end
