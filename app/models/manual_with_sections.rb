class ManualWithSections
  attr_accessor :sections, :removed_sections

  def initialize(sections: [], removed_sections: [])
    @sections = sections
    @removed_sections = removed_sections
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
