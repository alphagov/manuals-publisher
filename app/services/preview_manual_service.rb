class PreviewManualService
  def initialize(repository:, builder:, renderer:, manual_id:, attributes:, context:)
    @repository = repository
    @builder = builder
    @renderer = renderer
    @manual_id = manual_id
    @attributes = attributes
    @context = context
  end

  def call
    manual.update(attributes)

    renderer.call(manual)
  end

private

  attr_reader(
    :repository,
    :builder,
    :renderer,
    :manual_id,
    :attributes,
    :context,
  )

  def manual
    manual_id ? existing_manual : ephemeral_manual
  end

  def ephemeral_manual
    builder.call(
      attributes.reverse_merge(
        title: ""
      )
    )
  end

  def existing_manual
    @existing_manual ||= repository.fetch(manual_id)
  end
end
