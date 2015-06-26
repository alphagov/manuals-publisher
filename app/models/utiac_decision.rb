require "document_metadata_decorator"

class UtiacDecision < DocumentMetadataDecorator
  set_extra_field_names [
    :country,
    :country_guidance,
    :decision_reported,
    :judges,
    :promulgation_date,
  ]
end
