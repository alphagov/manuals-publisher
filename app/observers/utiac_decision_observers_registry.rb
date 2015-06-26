require "formatters/utiac_decision_artefact_formatter"
require "formatters/utiac_decision_indexable_formatter"
require "formatters/utiac_decision_publication_alert_formatter"
require "markdown_attachment_processor"

class UtiacDecisionObserversRegistry < AbstractSpecialistDocumentObserversRegistry

private
  def finder_schema
    SpecialistPublisherWiring.get(:utiac_decision_finder_schema)
  end

  def format_document_as_artefact(document)
    UtiacDecisionArtefactFormatter.new(document)
  end

  def format_document_for_indexing(document)
    UtiacDecisionIndexableFormatter.new(
      MarkdownAttachmentProcessor.new(document)
    )
  end

  def publication_alert_formatter(document)
    UtiacDecisionPublicationAlertFormatter.new(
      url_maker: url_maker,
      document: document,
    )
  end
end
