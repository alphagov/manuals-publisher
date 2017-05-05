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
    processed_body_1 = add_attachment_links(@section)
    processed_body_2 = render_govspeak(processed_body_1)
    render_footnotes_heading(processed_body_2)
  end

private

  def add_attachment_links(section)
    MarkdownAttachmentProcessor.new(section).body
  end

  def render_govspeak(body)
    GovspeakHtmlConverter.new.call(body)
  end

  def render_footnotes_heading(body)
    footnote_open_tag = '<div class="footnotes">'
    heading_tag = '<h2 id="footnotes">Footnotes</h2>'

    body.gsub(footnote_open_tag, "#{heading_tag}\\&")
  end
end
