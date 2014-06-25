class PreviewDocumentService
  def initialize(document_repository, document_builder, document_renderer, context)
    @document_repository = document_repository
    @document_builder = document_builder
    @document_renderer = document_renderer
    @context = context
  end

  def call(existing_document)
    @existing_document = existing_document
    document.update(document_params)

    document_renderer.call(document).body
  end

  private

  attr_reader(
    :document_repository,
    :document_builder,
    :document_renderer,
    :context,
    :existing_document,
  )

  def document
    existing_document || ephemeral_document
  end

  def ephemeral_document
    document_builder.call(document_params)
  end

  def document_params
    context.params.fetch("specialist_document")
  end
end
