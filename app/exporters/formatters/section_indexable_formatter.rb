require "formatters/abstract_indexable_formatter"

class SectionIndexableFormatter < AbstractIndexableFormatter
  RUMMAGER_DOCUMENT_TYPE = "manual_section".freeze

  def initialize(section, manual)
    @entity = section
    @manual = manual
  end

  def id
    path
  end

  def type
    RUMMAGER_DOCUMENT_TYPE
  end

  def indexable_attributes
    {
      title: "#{manual.title}: #{entity.title}",
      description: entity.summary,
      link: path,
      indexable_content: entity.body,
      public_timestamp: nil,
      content_store_document_type: type,
      manual: manual_path
    }
  end

private

  attr_reader :manual

  def manual_path
    root_path.join(manual.slug).to_s
  end

  def path
    root_path.join(entity.slug).to_s
  end
end
