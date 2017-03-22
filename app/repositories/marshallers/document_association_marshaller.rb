class DocumentAssociationMarshaller
  def initialize(decorator:, section_repository_factory:)
    @decorator = decorator
    @section_repository_factory = section_repository_factory
  end

  def load(manual, record)
    document_repository = section_repository_factory.call(manual)

    docs = Array(record.document_ids).map { |doc_id|
      document_repository.fetch(doc_id)
    }

    removed_docs = Array(record.removed_document_ids).map { |doc_id|
      begin
        document_repository.fetch(doc_id)
      rescue KeyError
        raise RemovedDocumentIdNotFoundError, "No document found for ID #{doc_id}"
      end
    }

    decorator.call(manual, sections: docs, removed_sections: removed_docs)
  end

  def dump(manual, record)
    document_repository = section_repository_factory.call(manual)

    manual.documents.each do |document|
      document_repository.store(document)
    end

    manual.removed_sections.each do |document|
      document_repository.store(document)
    end

    record.document_ids = manual.documents.map(&:id)
    record.removed_document_ids = manual.removed_sections.map(&:id)

    nil
  end

private

  attr_reader :section_repository_factory, :decorator

  class RemovedDocumentIdNotFoundError < StandardError; end
end
