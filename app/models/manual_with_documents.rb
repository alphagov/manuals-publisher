require "delegate"

class ManualWithDocuments < SimpleDelegator
  def self.create(attrs)
    ManualWithDocuments.new(
      SectionBuilder.new,
      Manual.new(attrs),
      sections: [],
    )
  end

  def initialize(section_builder, manual, sections:, removed_sections: [])
    @manual = manual
    @sections = sections
    @removed_sections = removed_sections
    @section_builder = section_builder
    super(manual)
  end

  def documents
    @sections.to_enum
  end

  def removed_documents
    @removed_sections.to_enum
  end

  def build_document(attributes)
    section = section_builder.call(
      self,
      attributes
    )

    add_section(section)

    section
  end

  def publish
    manual.publish do
      documents.each(&:publish!)
    end
  end

  def reorder_documents(document_order)
    unless document_order.sort == @sections.map(&:id).sort
      raise(
        ArgumentError,
        "document_order must contain each document_id exactly once",
      )
    end

    @sections.sort_by! { |doc| document_order.index(doc.id) }
  end

  def remove_document(document_id)
    found_document = @sections.find { |d| d.id == document_id }

    return if found_document.nil?

    removed = @sections.delete(found_document)

    return if removed.nil?

    @removed_sections << removed
  end

private

  attr_reader :section_builder, :manual

  def add_section(section)
    @sections << section
  end
end
