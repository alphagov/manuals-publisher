require "plek"

class SpecialistDocumentPublicationAlertFormatter
  def initialize(document)
    @document = document
  end

  def identifier
    "#{Plek.current.find("finder-frontend")}/#{slug_prefix}.atom"
  end

  def subject
    "The document '#{document.title}' has just been published."
  end

  def body
    "The document '#{document.title}' has just been published.\n" +
    "To view this document please visit:\n" +
    document_url
  end

private
  attr_reader(
    :document
  )

  def document_url
    "#{Plek.current.find("specialist-frontend")}/#{document.slug}"
  end

  def slug_prefix
    document.slug.split("/").first
  end
end
