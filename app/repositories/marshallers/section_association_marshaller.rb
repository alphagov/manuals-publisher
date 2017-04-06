class SectionAssociationMarshaller
  def dump(manual, edition)
    section_repository = SectionRepository.new(manual: manual)

    manual.sections.each do |section|
      section_repository.store(section)
    end

    manual.removed_sections.each do |section|
      section_repository.store(section)
    end

    edition.section_ids = manual.sections.map(&:id)
    edition.removed_section_ids = manual.removed_sections.map(&:id)

    nil
  end
end
