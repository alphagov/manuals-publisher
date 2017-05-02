require "rummager_indexer"

class SearchIndexAdapter
  def initialize
    @indexer = RummagerIndexer.new
  end

  def add(manual)
    @indexer.add(
      ManualIndexableFormatter.new(manual)
    )

    manual.sections.each do |section|
      @indexer.add(
        SectionIndexableFormatter.new(
          MarkdownAttachmentProcessor.new(section),
          manual,
        )
      )
    end

    manual.removed_sections.each do |section|
      remove_section(section, manual)
    end
  end

  def remove(manual)
    @indexer.delete(
      ManualIndexableFormatter.new(manual)
    )

    manual.sections.each do |section|
      remove_section(section, manual)
    end
  end

  def remove_section(section, manual)
    @indexer.delete(
      SectionIndexableFormatter.new(section, manual),
    )
  end
end
