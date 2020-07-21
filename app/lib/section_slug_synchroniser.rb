class SectionSlugSynchroniser
  attr_reader :logger, :manual, :sections

  def initialize(manual_slug, logger = STDOUT)
    @logger = logger
    @manual = Manual.find_by_slug!(manual_slug, User.gds_editor)
    @sections = manual.sections
  end

  def report
    amendments, conflicts = analyse_sections

    if amendments.empty? && conflicts.empty?
      log "All section slugs are in sync with their titles."
    else
      if amendments.any?
        log "The following sections can be reslugged:"
        amendments.each { |k, v| log "'#{k}' to '#{v}'" }
      end

      if conflicts.any?
        log "The following sections cannot be reslugged:"
        conflicts.each do |k, v|
          log "'#{k}' would change to '#{v}' but this is already in use."
        end
      end
    end
  end

  def synchronise
    amendments = analyse_sections.first
    amendments.each do |old_section_slug, new_section_slug|
      log "Reslugging #{old_section_slug} to #{new_section_slug}"
      SectionReslugger.new(manual.slug, old_section_slug, new_section_slug).call
    end
  end

private

  def analyse_sections
    amendments = {}
    conflicts = {}
    section_slugs = sections.map(&:slug)

    sections.each do |section|
      slugified_title = SlugGenerator.new(prefix: manual.slug).call(section.title)
      # Does the title match the slug?
      next if slugified_title == section.slug

      # Find updates which would conflict with existing slugs.
      if section_slugs.include?(slugified_title)
        conflicts[section.slug] = slugified_title
      else
        amendments[section.slug] = slugified_title
      end
    end

    [amendments, conflicts]
  end

  def log(str)
    logger.puts(str)
  end
end
