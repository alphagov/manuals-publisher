class ViewAdapterRegistry
  def for_document(document)
    get(document.document_type).new(document)
  end

  private

  def get(type)
    {
      "aaib_report" => AaibReportViewAdapter,
      "cma_case" => CmaCaseViewAdapter,
      "countryside_stewardship_grant" => CountrysideStewardshipGrantViewAdapter,
      "drug_safety_update" => DrugSafetyUpdateViewAdapter,
      "esi_fund" => EsiFundViewAdapter,
      "international_development_fund" => InternationalDevelopmentFundViewAdapter,
      "maib_report" => MaibReportViewAdapter,
      "medical_safety_alert" => MedicalSafetyAlertViewAdapter,
      "raib_report" => RaibReportViewAdapter,
      "utiac_decision" => UtiacDecisionViewAdapter,
      "vehicle_recalls_and_faults_alert" => VehicleRecallsAndFaultsAlertViewAdapter,
    }.fetch(type)
  end
end
