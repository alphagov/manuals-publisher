require "markdown_attachment_processor"
require "specialist_document_header_extractor"
require "govspeak_to_html_renderer"

class SpecialistDocumentRenderer
  def call(doc)
    pipeline = [
      MarkdownAttachmentProcessor.method(:new),
      SectionHeaderExtractor.create,
      GovspeakToHTMLRenderer.create,
    ]

    pipeline.reduce(doc) { |current_doc, next_renderer|
      next_renderer.call(current_doc)
    }
  end
end
