class SearchIndexAdapter
  RUMMAGER_DOCUMENT_TYPE_FOR_MANUAL = "manual".freeze
  RUMMAGER_DOCUMENT_TYPE_FOR_SECTION = "manual_section".freeze

  def initialize
    @rummager = Services.rummager
  end

  def add(manual)
    @rummager.add_document(
      RUMMAGER_DOCUMENT_TYPE_FOR_MANUAL,
      path_for(manual),
      title: manual.title,
      description: manual.summary,
      link: path_for(manual),
      indexable_content: manual.summary,
      public_timestamp: manual.updated_at,
      content_store_document_type: RUMMAGER_DOCUMENT_TYPE_FOR_MANUAL
    )

    manual.sections.each do |section|
      document = indexable_section(section, manual)
      @rummager.add_document(document.type, document.id, document.indexable_attributes)
    end

    manual.removed_sections.each do |section|
      remove_section(section, manual)
    end
  end

  def remove(manual)
    @rummager.delete_document(
      RUMMAGER_DOCUMENT_TYPE_FOR_MANUAL,
      path_for(manual)
    )

    manual.sections.each do |section|
      remove_section(section, manual)
    end
  end

  def remove_section(section, manual)
    document = indexable_section(section, manual)
    @rummager.delete_document(document.type, document.id)
  end

private

  def indexable_section(section, manual)
    OpenStruct.new(
      id: path_for(section),
      type: RUMMAGER_DOCUMENT_TYPE_FOR_SECTION,
      indexable_attributes: {
        title: "#{manual.title}: #{section.title}",
        description: section.summary,
        link: path_for(section),
        indexable_content: MarkdownAttachmentProcessor.new(section).body,
        public_timestamp: nil,
        content_store_document_type: RUMMAGER_DOCUMENT_TYPE_FOR_SECTION,
        manual: path_for(manual)
      }
    )
  end

  def path_for(model)
    Pathname.new('/').join(model.slug).to_s
  end
end
