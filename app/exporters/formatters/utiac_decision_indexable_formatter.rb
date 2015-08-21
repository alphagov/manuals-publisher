require "formatters/abstract_specialist_document_indexable_formatter"

class UtiacDecisionIndexableFormatter < AbstractSpecialistDocumentIndexableFormatter
  def type
    "utiac_decision"
  end

private
  def extra_attributes
    {
      country: entity.country,
      country_guidance: entity.country_guidance,
      decision_reported: entity.decision_reported,
      judges: entity.judges,
      promulgation_date: entity.promulgation_date,
    }
  end

  def organisation_slugs
    ["upper-tribunal-immigration-and-asylum-chamber"]
  end
end
