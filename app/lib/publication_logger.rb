class PublicationLogger
  def call(manual)
    manual.sections.each do |section|
      next unless section.needs_exporting?
      next if section.minor_update?
      next if section.change_note.blank?

      PublicationLog.create!(
        title: section.title,
        slug: section.slug,
        version_number: section.version_number,
        change_note: section.change_note,
      )
    end

    manual.removed_sections.each do |section|
      next if section.withdrawn?
      next if section.minor_update?
      next if section.change_note.blank?

      PublicationLog.create!(
        title: section.title,
        slug: section.slug,
        version_number: section.version_number,
        change_note: section.change_note,
      )
    end
  end
end
