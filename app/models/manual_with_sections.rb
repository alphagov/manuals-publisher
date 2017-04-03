class ManualWithSections
  attr_accessor :sections, :removed_sections

  def initialize(sections: [], removed_sections: [])
    @sections = sections
    @removed_sections = removed_sections
  end
end
