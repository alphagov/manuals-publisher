desc "Reslug and republish manual and sections"
task :reslug_and_republish_manual, %i[old_slug new_slug] => :environment do |_, args|
  logger = Logger.new(STDOUT)
  logger.formatter = Logger::Formatter.new

  manual = Manual.find_by_slug!(args[:old_slug], User.gds_editor)

  puts "Updating #{manual.slug} to #{args[:new_slug]}"

  Manual::UpdateService.new(
    user: User.gds_editor,
    manual_id: manual.id,
    attributes: { slug: args[:new_slug] },
  ).call

  puts "Republishing manual"
  republisher = ManualsRepublisher.new(logger)
  republisher.execute([manual])

  puts "Synchronising manual section slugs to #{args[:new_slug]}"
  synchroniser = SectionSlugSynchroniser.new(args[:new_slug], logger)
  synchroniser.synchronise

  puts "Manual and sections reslugged and republished"
end
