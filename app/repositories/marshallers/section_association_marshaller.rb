class SectionAssociationMarshaller
  def initialize(decorator:)
    @decorator = decorator
  end

  def load(manual, record)
    section_repository = SectionRepository.new(manual: manual)

    sections = Array(record.document_ids).map { |section_id|
      section_repository.fetch(section_id)
    }

    removed_sections = Array(record.removed_document_ids).map { |section_id|
      begin
        section_repository.fetch(section_id)
      rescue KeyError
        raise RemovedSectionIdNotFoundError, "No section found for ID #{section_id}"
      end
    }

    decorator.call(manual, sections: sections, removed_sections: removed_sections)
  end

  def dump(manual, record)
    section_repository = SectionRepository.new(manual: manual)

    manual.sections.each do |section|
      section_repository.store(section)
    end

    manual.removed_sections.each do |section|
      section_repository.store(section)
    end

    record.document_ids = manual.sections.map(&:id)
    record.removed_document_ids = manual.removed_sections.map(&:id)

    nil
  end

private

  attr_reader :decorator

  class RemovedSectionIdNotFoundError < StandardError; end
end
