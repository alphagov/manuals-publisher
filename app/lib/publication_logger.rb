class PublicationLogger
  def call(manual)
    manual.sections.each do |doc|
      next unless doc.needs_exporting?
      next if doc.minor_update?

      PublicationLog.create!(
        title: doc.title,
        slug: doc.slug,
        version_number: doc.version_number,
        change_note: doc.change_note,
      )
    end

    manual.removed_sections.each do |doc|
      next if doc.withdrawn?
      next if doc.minor_update?

      PublicationLog.create!(
        title: doc.title,
        slug: doc.slug,
        version_number: doc.version_number,
        change_note: doc.change_note,
      )
    end
  end
end
