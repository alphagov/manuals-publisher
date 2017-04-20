class SectionSlugSynchroniser
  attr_reader :logger, :manual, :sections

  def initialize(manual_slug, logger = STDOUT)
    @logger = logger
    manual_record = ManualRecord.where(slug: manual_slug).last
    @manual = Manual.find(manual_record.manual_id, User.gds_editor)
    @sections = manual.sections
  end

  def report
    amendments, conflicts = analyse_sections

    if amendments.any?
      log "The following sections can be reslugged:"
      amendments.each { |k, v| log "'#{section_slug(k)}' to '#{section_slug(v)}'" }
    end

    if conflicts.any?
      log "The following sections cannot be reslugged:"
      conflicts.each do |k, v|
        log "'#{section_slug(k)}' would change to '#{section_slug(v)}' but this is already in use."
      end
    end
  end

  def synchronise
    amendments = analyse_sections.first
    amendments.each do |full_old_section_slug, full_new_section_slug|
      old_section_slug = section_slug(full_old_section_slug)
      new_section_slug = section_slug(full_new_section_slug)
      log "Reslugging #{full_old_section_slug} to #{full_new_section_slug}"
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

  def section_slug(slug)
    slug.split("/").last
  end

  def log(str)
    logger.puts(str)
  end
end
