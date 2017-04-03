class ManualWithSections
  attr_writer :sections, :removed_sections

  def initialize(manual, sections: [], removed_sections: [])
    @manual = manual
    @sections = sections
    @removed_sections = removed_sections
    @section_builder = SectionBuilder.new
  end

  def sections
    @sections.to_enum
  end

  def removed_sections
    @removed_sections.to_enum
  end

  def build_section(attributes)
    section = section_builder.call(
      manual,
      attributes
    )

    add_section(section)

    section
  end

  def publish
    manual.__publish__ do
      sections.each(&:publish!)
    end
  end

  def reorder_sections(section_order)
    unless section_order.sort == @sections.map(&:id).sort
      raise(
        ArgumentError,
        "section_order must contain each section_id exactly once",
      )
    end

    @sections.sort_by! { |doc| section_order.index(doc.id) }
  end

  def remove_section(section_id)
    found_section = @sections.find { |d| d.id == section_id }

    return if found_section.nil?

    removed = @sections.delete(found_section)

    return if removed.nil?

    @removed_sections << removed
  end

private

  attr_reader :section_builder, :manual

  def add_section(section)
    @sections << section
  end
end
