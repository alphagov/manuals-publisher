class ManualDocumentBuilder
  def initialize(dependencies)
    @factory_factory = dependencies.fetch(:factory_factory)
    @id_generator = dependencies.fetch(:id_generator)
  end

  def call(manual, attrs)
    attrs = attrs.stringify_keys

    document = @factory_factory
      .call(manual)
      .call(
        @id_generator.call,
        editions,
      )

    document.update(attrs.reverse_merge(defaults))

    document
  end

private

  def defaults
    {
      "document_type" => document_type,
      "change_note" => "New section added.",
    }
  end

  def document_type
    "manual"
  end

  def editions
    []
  end
end
