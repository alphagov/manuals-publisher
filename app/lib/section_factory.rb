class SectionFactory
  def initialize(manual)
    @manual = manual
  end

  def call(id, editions)
    slug_generator = SlugGenerator.new(prefix: @manual.slug)

    ChangeNoteValidator.new(
      SectionValidator.new(
        Section.new(
          slug_generator,
          id,
          editions,
        ),
      )
    )
  end
end
