class SectionRepository
  def fetch(section_id)
    editions = SectionEdition.all
      .where(section_id: section_id)
      .order_by([:version_number, :desc])
      .limit(2)
      .to_a
      .reverse

    if editions.empty?
      raise KeyError.new("key not found #{section_id}")
    else
      Section.build(manual: manual, id: section_id, editions: editions)
    end
  end

  def initialize(manual:)
    @manual = manual
  end

  def store(section)
    # It is actually only necessary to save the latest edition, however, I
    # think it's safer to save latest two as both are exposed to the and have
    # potential to change. This extra write may save a potential future
    # headache.
    section.editions.last(2).each(&:save!)

    self
  end

private

  attr_reader(
    :manual,
  )
end
