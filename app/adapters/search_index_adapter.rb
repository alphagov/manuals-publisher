require "rummager_indexer"

class SearchIndexAdapter
  def add(manual)
    indexer = RummagerIndexer.new

    indexer.add(
      ManualIndexableFormatter.new(manual)
    )

    manual.sections.each do |section|
      indexer.add(
        SectionIndexableFormatter.new(
          MarkdownAttachmentProcessor.new(section),
          manual,
        )
      )
    end

    manual.removed_sections.each do |section|
      indexer.delete(
        SectionIndexableFormatter.new(section, manual),
      )
    end
  end

  def remove(manual)
    indexer = RummagerIndexer.new

    indexer.delete(
      ManualIndexableFormatter.new(manual)
    )

    manual.sections.each do |section|
      indexer.delete(
        SectionIndexableFormatter.new(
          MarkdownAttachmentProcessor.new(section),
          manual,
        )
      )
    end
  end
end
