require "builders/specialist_document_builder"

class CmaCaseBuilder < SpecialistDocumentBuilder
private
  def document_type
    "cma_case"
  end
end
