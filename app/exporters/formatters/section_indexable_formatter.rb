require "formatters/abstract_indexable_formatter"

class SectionIndexableFormatter < AbstractIndexableFormatter
  RUMMAGER_DOCUMENT_TYPE = "manual_section".freeze

  def initialize(section, manual)
    @section = section
    @manual = manual
  end

  def id
    root_path.join(@section.slug).to_s
  end

  def type
    RUMMAGER_DOCUMENT_TYPE
  end

  def indexable_attributes
    {
      title: "#{@manual.title}: #{@section.title}",
      description: @section.summary,
      link: root_path.join(@section.slug).to_s,
      indexable_content: @section.body,
      public_timestamp: nil,
      content_store_document_type: type,
      manual: root_path.join(@manual.slug).to_s
    }
  end
end
