class UtiacDecisionViewAdapter < DocumentViewAdapter
  attributes = [
    :country,
    :country_guidance,
    :decision_reported,
    :judges,
    :promulgation_date,
  ]

  def self.model_name
    ActiveModel::Name.new(self, nil, "UtiacDecision")
  end

  attributes.each do |attribute_name|
    define_method(attribute_name) do
      delegate_if_document_exists(attribute_name)
    end
  end

private

  def finder_schema
    SpecialistPublisherWiring.get(:utiac_decision_finder_schema)
  end
end
