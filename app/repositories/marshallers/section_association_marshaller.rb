class SectionAssociationMarshaller
  class Decorator
    def call(manual, attrs)
      manual.sections = attrs.fetch(:sections, [])
      manual.removed_sections = attrs.fetch(:removed_sections, [])
      ManualValidator.new(
        NullValidator.new(
          manual
        )
      )
    end
  end

  def load(manual, edition)
    section_repository = SectionRepository.new(manual: manual)

    sections = Array(edition.section_ids).map { |section_id|
      section_repository.fetch(section_id)
    }

    removed_sections = Array(edition.removed_section_ids).map { |section_id|
      begin
        section_repository.fetch(section_id)
      rescue KeyError
        raise RemovedSectionIdNotFoundError, "No section found for ID #{section_id}"
      end
    }

    Decorator.new.call(manual, sections: sections, removed_sections: removed_sections)
  end

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

private

  attr_reader :decorator

  class RemovedSectionIdNotFoundError < StandardError; end
end
