require "rummager_indexer"

class SearchIndexAdapter
  def initialize
    @indexer = RummagerIndexer.new
  end

  def add(manual)
    @indexer.add(indexable_manual(manual))

    manual.sections.each do |section|
      @indexer.add(indexable_section(section, manual))
    end

    manual.removed_sections.each do |section|
      remove_section(section, manual)
    end
  end

  def remove(manual)
    @indexer.delete(indexable_manual(manual))

    manual.sections.each do |section|
      remove_section(section, manual)
    end
  end

  def remove_section(section, manual)
    @indexer.delete(indexable_section(section, manual))
  end

private

  def indexable_manual(manual)
    ManualIndexableFormatter.new(manual)
  end

  def indexable_section(section, manual)
    SectionIndexableFormatter.new(
      MarkdownAttachmentProcessor.new(section),
      manual,
    )
  end
end
