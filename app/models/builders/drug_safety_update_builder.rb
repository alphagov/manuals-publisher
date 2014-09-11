require "builders/specialist_document_builder"

class DrugSafetyUpdateReportBuilder < SpecialistDocumentBuilder

  def call(attrs)
    attrs.merge!(document_type: "drug_safety_update")
    super(attrs)
  end

end
