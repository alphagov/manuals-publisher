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
    original_body = @section.body

    processed_body_1 = MarkdownAttachmentProcessor.method(:new).call(
      OpenStruct.new(body: original_body, attachments: @section.attachments)
    ).body

    processed_body_2 = GovspeakToHTMLRenderer.create.call(
      OpenStruct.new(body: processed_body_1)
    ).body

    processed_body_3 = FootnotesSectionHeadingRenderer.create.call(
      OpenStruct.new(body: processed_body_2)
    ).body

    processed_body_3
  end
end
