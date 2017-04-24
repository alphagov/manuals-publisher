class SectionRepository
  def store(section)
    # It is actually only necessary to save the latest edition, however, I
    # think it's safer to save latest two as both are exposed to the and have
    # potential to change. This extra write may save a potential future
    # headache.
    section.editions.last(2).each(&:save!)

    self
  end
end
