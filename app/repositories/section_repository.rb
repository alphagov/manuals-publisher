class SectionRepository
  NotFoundError = Module.new

  def fetchable_fetch(key)
    result = public_send(:[], key)

    if result.nil?
      raise KeyError.new("key not found #{key}")
    else
      result
    end
  end

  def fetch(section_id)
    fetchable_fetch(section_id)
  rescue KeyError => e
    raise e.extend(NotFoundError)
  end

  def initialize(manual:)
    @manual = manual
  end

  def [](id)
    editions = SectionEdition.all
      .where(section_id: id)
      .order_by([:version_number, :desc])
      .limit(2)
      .to_a
      .reverse

    if editions.empty?
      nil
    else
      Section.build(manual: manual, id: id, editions: editions)
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

private

  attr_reader(
    :manual,
  )
end
