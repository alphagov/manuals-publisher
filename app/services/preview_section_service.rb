class PreviewSectionService
  def initialize(manual_repository, document_builder, document_renderer, context)
    @manual_repository = manual_repository
    @document_builder = document_builder
    @document_renderer = document_renderer
    @context = context
  end

  def call
    section.update(section_params)

    document_renderer.call(section)
  end

private

  attr_reader(
    :manual_repository,
    :document_builder,
    :document_renderer,
    :context,
  )

  def section
    section_id ? existing_section : ephemeral_section
  end

  def manual
    manual_repository.fetch(manual_id)
  end

  def ephemeral_section
    document_builder.call(manual, section_params)
  end

  def existing_section
    @existing_section ||= manual.sections.find { |section|
      section.id == section_id
    }
  end

  def section_params
    context.params.fetch("document")
  end

  def section_id
    context.params.fetch("id", nil)
  end

  def manual_id
    context.params.fetch("manual_id", nil)
  end
end
