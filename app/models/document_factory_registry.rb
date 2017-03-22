require "validators/change_note_validator"
require "validators/section_validator"
require "validators/manual_validator"
require "validators/null_validator"

require "builders/section_builder"
require "manual_with_sections"
require "slug_generator"
require "section"

class DocumentFactoryRegistry
  def manual_with_sections
    ->(manual, attrs) {
      ManualValidator.new(
        NullValidator.new(
          ManualWithSections.new(
            SectionBuilder.new,
            manual,
            attrs,
          )
        )
      )
    }
  end
end
