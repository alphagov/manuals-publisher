class PreviewSectionService
  def initialize(section_renderer:, context:)
    @section_renderer = section_renderer
    @context = context
  end

  def call
    section.update(section_params)

    section_renderer.call(section)
  end

private

  attr_reader(
    :section_renderer,
    :context,
  )

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
