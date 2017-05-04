require "markdown_attachment_processor"
require "section_header_extractor"
require "govspeak_to_html_renderer"
require "footnotes_section_heading_renderer"

class SectionPresenter
  def initialize(section)
    @section = section
  end

  def fetch(key)
    call.attributes.fetch(key)
  end

  def valid?
    call.valid?
  end

  def errors
    call.errors
  end

  def body
    call.body
  end

private

  def call
    pipeline = [
      MarkdownAttachmentProcessor.method(:new),
      SectionHeaderExtractor.create,
      GovspeakToHTMLRenderer.create,
      FootnotesSectionHeadingRenderer.create,
    ]

    pipeline.reduce(@section) { |current_section, next_renderer|
      next_renderer.call(current_section)
    }
  end
end
