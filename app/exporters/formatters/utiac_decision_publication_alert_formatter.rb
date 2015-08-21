require "formatters/abstract_document_publication_alert_formatter"

class UtiacDecisionPublicationAlertFormatter < AbstractDocumentPublicationAlertFormatter

  def name
    "Upper Tribunal Immigration and Asylum Chamber decisions"
  end

private
  def document_noun
    "decision"
  end
end
