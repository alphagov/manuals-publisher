require "services"
require "gds_api_constants"

class SearchIndexAdapter
  def add(manual)
    rummager.add_document(
      GdsApiConstants::Rummager::MANUAL_DOCUMENT_TYPE,
      path_for(manual),
      title: manual.title,
      description: manual.summary,
      link: path_for(manual),
      indexable_content: manual.summary,
      public_timestamp: manual.updated_at,
      content_store_document_type: GdsApiConstants::Rummager::MANUAL_DOCUMENT_TYPE
    )

    manual.sections.each do |section|
      rummager.add_document(
        GdsApiConstants::Rummager::SECTION_DOCUMENT_TYPE,
        path_for(section),
        title: "#{manual.title}: #{section.title}",
        description: section.summary,
        link: path_for(section),
        indexable_content: MarkdownAttachmentProcessor.new(section).body,
        public_timestamp: nil,
        content_store_document_type: GdsApiConstants::Rummager::SECTION_DOCUMENT_TYPE,
        manual: path_for(manual)
      )
    end

    manual.removed_sections.each do |section|
      remove_section(section)
    end
  end

  def remove(manual)
    rummager.delete_document(
      GdsApiConstants::Rummager::MANUAL_DOCUMENT_TYPE,
      path_for(manual)
    )

    manual.sections.each do |section|
      remove_section(section)
    end
  end

  def remove_section(section)
    rummager.delete_document(
      GdsApiConstants::Rummager::SECTION_DOCUMENT_TYPE,
      path_for(section)
    )
  end

private

  def path_for(model)
    Pathname.new('/').join(model.slug).to_s
  end

  def rummager
    Services.rummager
  end
end
