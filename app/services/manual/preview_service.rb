class Manual::PreviewService
  def initialize(renderer:, manual_id:, attributes:, context:)
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
    :renderer,
    :manual_id,
    :attributes,
    :context,
  )

  def manual
    manual_id ? existing_manual : ephemeral_manual
  end

  def ephemeral_manual
    Manual.build(
      attributes.reverse_merge(
        title: ""
      )
    )
  end

  def existing_manual
    @existing_manual ||= Manual.find(manual_id, context.current_user)
  end
end
