class SearchIndexAdapter
  def initialize
    @rummager = Services.rummager
  end

  def add(manual)
    document = indexable_manual(manual)
    @rummager.add_document(document.type, document.id, document.indexable_attributes)

    manual.sections.each do |section|
      document = indexable_section(section, manual)
      @rummager.add_document(document.type, document.id, document.indexable_attributes)
    end

    manual.removed_sections.each do |section|
      remove_section(section, manual)
    end
  end

  def remove(manual)
    document = indexable_manual(manual)
    @rummager.delete_document(document.type, document.id)

    manual.sections.each do |section|
      remove_section(section, manual)
    end
  end

  def remove_section(section, manual)
    document = indexable_section(section, manual)
    @rummager.delete_document(document.type, document.id)
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
