require "validators/change_note_validator"
require "validators/section_validator"
require "validators/manual_validator"
require "validators/null_validator"

require "builders/section_builder"
require "manual_with_documents"
require "slug_generator"
require "section"

class DocumentFactoryRegistry
  def manual_with_documents
    ->(manual, attrs) {
      ManualValidator.new(
        NullValidator.new(
          ManualWithDocuments.new(
            SectionBuilder.new,
            manual,
            attrs,
          )
        )
      )
    }
  end

  def section_factory_factory
    ->(manual) {
      ->(id, editions) {
        slug_generator = SlugGenerator.new(prefix: manual.slug)

        ChangeNoteValidator.new(
          SectionValidator.new(
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
