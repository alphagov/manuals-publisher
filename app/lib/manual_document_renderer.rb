require "markdown_attachment_processor"
require "section_header_extractor"
require "govspeak_to_html_renderer"
require "footnotes_section_heading_renderer"

class ManualDocumentRenderer
  def call(doc)
    pipeline = [
      MarkdownAttachmentProcessor.method(:new),
      SectionHeaderExtractor.create,
      GovspeakToHTMLRenderer.create,
      FootnotesSectionHeadingRenderer.create,
    ]

    pipeline.reduce(doc) { |current_doc, next_renderer|
      next_renderer.call(current_doc)
    }
  end
end
