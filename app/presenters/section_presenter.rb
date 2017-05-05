require "markdown_attachment_processor"
require "govspeak_to_html_renderer"
require "footnotes_section_heading_renderer"

class SectionPresenter
  def initialize(section)
    @section = section
  end

  delegate :slug, to: :@section
  delegate :title, to: :@section
  delegate :summary, to: :@section
  delegate :valid?, to: :@section
  delegate :errors, to: :@section

  def body
    original_section = @section

    processed_section_1 = MarkdownAttachmentProcessor.method(:new).call(original_section)
    processed_section_2 = GovspeakToHTMLRenderer.create.call(processed_section_1)
    processed_section_3 = FootnotesSectionHeadingRenderer.create.call(processed_section_2)

    processed_section_3.attributes.fetch(:body)
  end
end
