require "formatters/abstract_document_publication_alert_formatter"

class UtaacDecisionPublicationAlertFormatter < AbstractDocumentPublicationAlertFormatter

  def name
    "Administrative appeals tribunal decisions"
  end

private
  def document_noun
    "decision"
  end
end
