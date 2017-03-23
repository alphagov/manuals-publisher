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
