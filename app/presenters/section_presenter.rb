require "markdown_attachment_processor"
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
    processed_body_1 = add_attachment_links(@section)
    processed_body_2 = render_govspeak(processed_body_1)
    render_footnotes_heading(processed_body_2)
  end

private

  def add_attachment_links(section)
    MarkdownAttachmentProcessor.method(:new).call(section).body
  end

  def render_govspeak(body)
    GovspeakHtmlConverter.new.call(body)
  end

  def render_footnotes_heading(body)
    FootnotesSectionHeadingRenderer.create.call(
      OpenStruct.new(body: body)
    ).body
  end
end
