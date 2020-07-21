require "logger"

def usage
  warn <<~USAGE
    USAGE: rake reslug_section[manual_slug, old_section_slug, new_section_slug]

    manual_slug:
      slug of manual (eg 'guidance/countryside-stewardship-manual')

    old_section_slug:
      current slug of section to be renamed (eg 'guidance/countryside-stewardship-manual/8-terms-and-conditions')

    new_section_slug:
      new slug for section (eg 'guidance/countryside-stewardship-manual/8-scheme-requirements-and-procedures')
  USAGE

  exit(1)
end

def logger
  @logger ||= begin
    logger = Logger.new(STDOUT)
    logger.formatter = Logger::Formatter.new
    logger
  end
end

desc "Reslug section"
task :reslug_section, %i[manual_slug old_section_slug new_section_slug] => :environment do |_, args|
  usage unless args.key?(:manual_slug) && args.key?(:old_section_slug) && args.key?(:new_section_slug)

  logger.info "Renaming section slug"

  begin
    SectionReslugger.new(args[:manual_slug], args[:old_section_slug], args[:new_section_slug]).call
    logger.info "Republishing of manual section complete."
  rescue SectionReslugger::Error => e
    logger.error(e)
  end
end
