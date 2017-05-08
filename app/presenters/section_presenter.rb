require "markdown_attachment_processor"

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
    body_with_attachment_links = add_attachment_links_to_section_body(@section)
    body_with_rendered_govspeak = render_govspeak(body_with_attachment_links)
    render_footnotes_heading(body_with_rendered_govspeak)
  end

private

  def add_attachment_links_to_section_body(section)
    MarkdownAttachmentProcessor.new(section).body
  end

  def render_govspeak(body)
    Govspeak::Document.new(body).to_html
  end

  def render_footnotes_heading(body)
    footnote_open_tag = '<div class="footnotes">'
    heading_tag = '<h2 id="footnotes">Footnotes</h2>'

    body.gsub(footnote_open_tag, "#{heading_tag}\\&")
  end
end
