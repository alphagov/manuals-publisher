class AlreadyPublishedError < StandardError
  attr_reader :manual, :document

  def initialize(manual, document)
    @manual = manual
    @document = document
  end

  def message
    "This document cannot be deleted as it has already been published"
  end
end

class DestroyManualDocumentService
  def initialize(dependencies)
    @manual_repository = dependencies.fetch(:manual_repository)
    @manual_id = dependencies.fetch(:manual_id)
    @document_id = dependencies.fetch(:document_id)
  end

  def call
    if document_destroyable?
      destroy_document
      [manual, nil]
    else
      raise AlreadyPublishedError.new(manual, document)
    end
  end

private
  attr_reader :manual_repository, :document_id, :manual_id

  def document_destroyable?
    manual.draft? && document.never_published? && document.editions.size == 1
  end

  def destroy_document
    manual.remove_document(document)
    manual_repository.store(manual)
    document.destroy_latest_edition
  end

  def document
    @document ||= manual.documents.find { |d| d.id == document_id }
  end

  def manual
    @manual ||= manual_repository.fetch(manual_id)
  end
end
