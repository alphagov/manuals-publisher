require "formatters/abstract_artefact_formatter"

class UtiacDecisionArtefactFormatter < AbstractArtefactFormatter

  def state
    state_mapping.fetch(entity.publication_state)
  end

  def kind
    "utiac_decision"
  end

  def rendering_app
    "specialist-frontend"
  end

  def organisation_slugs
    ["upper-tribunal-immigration-and-asylum-chamber"]
  end
end
