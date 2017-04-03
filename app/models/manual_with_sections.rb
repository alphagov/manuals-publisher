class ManualWithSections
  attr_accessor :sections, :removed_sections

  def initialize(sections: [], removed_sections: [])
    @sections = sections
    @removed_sections = removed_sections
  end

  def reorder_sections(section_order)
    unless section_order.sort == sections.map(&:id).sort
      raise(
        ArgumentError,
        "section_order must contain each section_id exactly once",
      )
    end

    sections.sort_by! { |sec| section_order.index(sec.id) }
  end

  def remove_section(section_id)
    found_section = sections.find { |d| d.id == section_id }

    return if found_section.nil?

    removed = sections.delete(found_section)

    return if removed.nil?

    removed_sections << removed
  end

  def add_section(section)
    sections << section
  end
end
