class SectionRepository
  def fetch(manual, section_id)
    editions = SectionEdition.two_latest_versions(section_id).to_a.reverse

    if editions.empty?
      raise KeyError.new("key not found #{section_id}")
    else
      Section.build(manual: manual, id: section_id, editions: editions)
    end
  end

  def store(section)
    # It is actually only necessary to save the latest edition, however, I
    # think it's safer to save latest two as both are exposed to the and have
    # potential to change. This extra write may save a potential future
    # headache.
    section.editions.last(2).each(&:save!)

    self
  end
end
