class ShowManualService
  def initialize(manual_id:, manual_repository:, context:)
    @manual_id = manual_id
    @manual_repository = manual_repository
    @context = context
  end

  def call
    [
      manual,
      other_metadata,
    ]
  end

private

  attr_reader(
    :manual_id,
    :manual_repository,
    :context,
  )

  def manual
    @manual ||= Manual.find(manual_id, context.current_user)
  end

  def other_metadata
    {
      slug_unique: slug_unique?,
      clashing_sections: clashing_sections,
    }
  end

  def slug_unique?
    manual_repository.slug_unique?(manual)
  end

  def clashing_sections
    manual.sections
      .group_by(&:slug)
      .select { |_slug, docs| docs.size > 1 }
  end
end
