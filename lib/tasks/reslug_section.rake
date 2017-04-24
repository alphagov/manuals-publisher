require "section_reslugger"
require "logger"

desc "Reslug section"
task :reslug_section, [:manual_slug, :old_section_slug, :new_section_slug] => :environment do |_, args|
  def usage
    $stderr.puts %{
USAGE: rake reslug_section[manual_slug, old_section_slug, new_section_slug]

manual_slug:
  slug of manual (eg 'guidance/countryside-stewardship-manual')

old_section_slug:
  current slug of section to be renamed (eg '8-terms-and-conditions')

new_section_slug:
  new slug for section (eg '8-scheme-requirements-and-procedures')

}
    exit(1)
  end

  def logger
    @logger ||= begin
                  logger = Logger.new(STDOUT)
                  logger.formatter = Logger::Formatter.new
                  logger
                end
  end

  usage unless args.has_key?(:manual_slug) && args.has_key?(:old_section_slug) && args.has_key?(:new_section_slug)

  logger.info "Renaming section slug"

  begin
    SectionReslugger.new(args[:manual_slug], args[:old_section_slug], args[:new_section_slug]).call
    logger.info "Republishing of manual section complete."
  rescue SectionReslugger::Error => e
    logger.error(e)
  end
end
