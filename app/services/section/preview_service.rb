require 'markdown_attachment_processor'
require 'section_header_extractor'
require 'govspeak_to_html_renderer'
require 'footnotes_section_heading_renderer'

class Section::PreviewService
  def initialize(context:)
    @context = context
  end

  def call
    section.update(section_params)

    render(section)
  end

  def render(section)
    pipeline = [
      MarkdownAttachmentProcessor.method(:new),
      SectionHeaderExtractor.create,
      GovspeakToHTMLRenderer.create,
      FootnotesSectionHeadingRenderer.create,
    ]

    pipeline.reduce(section) { |current_section, next_renderer|
      next_renderer.call(current_section)
    }
  end

private

  attr_reader(:context)

  def section
    section_id ? existing_section : ephemeral_section
  end

  def manual
    Manual.find(manual_id, context.current_user)
  end

  def ephemeral_section
    manual.build_section(section_params)
  end

  def existing_section
    @existing_section ||= manual.sections.find { |section|
      section.id == section_id
    }
  end

  def section_params
    context.params.fetch("section")
  end

  def section_id
    context.params.fetch("id", nil)
  end

  def manual_id
    context.params.fetch("manual_id", nil)
  end
end
