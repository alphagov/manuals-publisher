require "markdown_attachment_processor"
require "specialist_document_header_extractor"
require "govspeak_to_html_renderer"

class SpecialistDocumentRenderer
  def self.create
    ->(doc) {
      pipeline = [
        MarkdownAttachmentProcessor.method(:new),
        SpecialistDocumentHeaderExtractor.create,
        GovspeakToHTMLRenderer.create,
      ]

      pipeline.reduce(doc) { |current_doc, next_renderer|
        next_renderer.call(current_doc)
      }
    }
  end
end
