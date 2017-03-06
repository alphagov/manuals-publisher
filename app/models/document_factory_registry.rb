require "validators/change_note_validator"
require "validators/manual_document_validator"
require "validators/manual_validator"
require "validators/null_validator"

require "builders/manual_document_builder"
require "manual_with_documents"
require "slug_generator"
require "specialist_document"

class DocumentFactoryRegistry
  def self.validatable_document_factories
    new
  end

  def manual_with_documents
    ->(manual, attrs) {
      ManualValidator.new(
        NullValidator.new(
          ManualWithDocuments.new(
            manual_document_builder,
            manual,
            attrs,
          )
        )
      )
    }
  end

  def manual_document_builder
    ManualDocumentBuilder.new(factory_factory: manual_document_factory_factory)
  end

  def manual_document_factory_factory
    ->(manual) {
      ->(id, editions) {
        slug_generator = SlugGenerator.new(prefix: manual.slug)

        ChangeNoteValidator.new(
          ManualDocumentValidator.new(
            Section.new(
              slug_generator,
              id,
              editions,
            ),
          )
        )
      }
    }
  end
end
