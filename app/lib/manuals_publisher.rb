module ManualsPublisher
  extend self

  def attachment_services(document_type)
    AbstractAttachmentServiceRegistry.new(
      repository: document_repositories.for_type(document_type)
    )
  end

  def document_services(document_type)
    AbstractDocumentServiceRegistry.new(
      repository: document_repositories.for_type(document_type),
      builder: ManualsPublisherWiring.get("#{document_type}_builder".to_sym),
      observers: observer_registry(document_type),
    )
  end

  def view_adapter(document)
    view_adapters.for_document(document)
  end

  def document_types
    OBSERVER_MAP.keys
  end

private
  OBSERVER_MAP = {
    "aaib_report" => AaibReportObserversRegistry,
    "asylum_support_decision" => AsylumSupportDecisionObserversRegistry,
    "cma_case" => CmaCaseObserversRegistry,
    "countryside_stewardship_grant" => CountrysideStewardshipGrantObserversRegistry,
    "drug_safety_update" => DrugSafetyUpdateObserversRegistry,
    "employment_appeal_tribunal_decision" => EmploymentAppealTribunalDecisionObserversRegistry,
    "employment_tribunal_decision" => EmploymentTribunalDecisionObserversRegistry,
    "esi_fund" => EsiFundObserversRegistry,
    "international_development_fund" => InternationalDevelopmentFundObserversRegistry,
    "maib_report" => MaibReportObserversRegistry,
    "medical_safety_alert" => MedicalSafetyAlertObserversRegistry,
    "raib_report" => RaibReportObserversRegistry,
    "tax_tribunal_decision" => TaxTribunalDecisionObserversRegistry,
    "utaac_decision" => UtaacDecisionObserversRegistry,
    "vehicle_recalls_and_faults_alert" => VehicleRecallsAndFaultsAlertObserversRegistry,
  }.freeze

  ORGANISATIONS = {
    "aaib_report" => %w(
      38eb5d8f-2d89-480c-8655-e2e7ac23f8f4
    ), # air-accidents-investigation-branch
    "asylum_support_decision" => %w(
      7141e343-e7bb-483b-920a-c6a5cf8f758c
    ), # first-tier-tribunal-asylum-support
    "cma_case" => %w(
      957eb4ec-089b-4f71-ba2a-dc69ac8919ea
    ), # competition-and-markets-authority
    "countryside_stewardship_grant" => %w(
      8bf5624b-dec2-44fa-9b6c-daed166333a5
      de4e9dc6-cca4-43af-a594-682023b84d6c
      d3ce4ba7-bc75-46b4-89d9-38cb3240376d
    ), # natural-england, department-for-environment-food-rural-affairs, forestry-commission
    "drug_safety_update" => %w(
      240f72bd-9a4d-4f39-94d9-77235cadde8e
    ), # medicines-and-healthcare-products-regulatory-agency
    "employment_appeal_tribunal_decision" => %w(
      caeb418c-d11c-4352-92e9-47b21289f696
    ), # employment-appeal-tribunal
    "employment_tribunal_decision" => %w(
      8bb37087-a5a7-4493-8afe-900b36ebc927
    ), # employment-tribunal
    "esi_fund" => %w(), # none
    "international_development_fund" => %w(
      db994552-7644-404d-a770-a2fe659c661f
    ), # department-for-international-development
    "maib_report" => %w(
      9c66b9a3-1e6a-48e8-974d-2a5635f84679
    ), # marine-accident-investigation-branch
    "medical_safety_alert" => %w(
      240f72bd-9a4d-4f39-94d9-77235cadde8e
    ), # medicines-and-healthcare-products-regulatory-agency
    "raib_report" => %w(
      013872d8-8bbb-4e80-9b79-45c7c5cf9177
    ), # rail-accident-investigation-branch
    "tax_tribunal_decision" => %w(
      1a68b2cc-eb52-4528-8989-429f710da00f
    ), # upper-tribunal-tax-and-chancery-chamber
    "utaac_decision" => %w(
      4c2e325a-2d95-442b-856a-e7fb9f9e3cf8
    ), # upper-tribunal-administrative-appeals-chamber
    "vehicle_recalls_and_faults_alert" => %w(
      d39237a5-678b-4bb5-a372-eb2cb036933d
    ), # driver-and-vehicle-standards-agency
  }

  def view_adapters
    ManualsPublisherWiring.get(:view_adapter_registry)
  end

  def document_repositories
    ManualsPublisherWiring.get(:repository_registry)
  end

  def observer_registry(document_type)
    OBSERVER_MAP.fetch(document_type).new(ORGANISATIONS.fetch(document_type, []))
  end
end
