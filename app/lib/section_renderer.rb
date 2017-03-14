require "markdown_attachment_processor"
require "section_header_extractor"
require "govspeak_to_html_renderer"

class SectionRenderer
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
