class SpecialistDocumentBuilder
  def initialize(dependencies)
    @document_factory = dependencies.fetch(:factory)
    @id_generator = dependencies.fetch(:id_generator)
    @document_type = dependencies.fetch(:document_type) { document_type }
  end

  def call(attrs)
    attrs = attrs.stringify_keys

    document_factory
      .call(
        new_document_id,
        editions,
      )
      .tap { |d|
        d.update(
          attrs.merge(
            document_type: document_type,
          )
        )
      }
  end

  private

  attr_reader :document_factory, :id_generator

  def new_document_id
    id_generator.call
  end

  def editions
    []
  end

  def document_type
    @document_type || raise(NotImplementedError)
  end
end
