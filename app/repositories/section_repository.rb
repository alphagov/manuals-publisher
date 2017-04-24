require "fetchable"

class SectionRepository
  include Fetchable

  NotFoundError = Module.new

  def fetch(*args, &block)
    super
  rescue KeyError => e
    raise e.extend(NotFoundError)
  end

  def initialize(manual:)
    @manual = manual
  end

  def [](id)
    editions = section_editions
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

  def slug_unique?(section)
    # TODO: push this method down into persistence layer
    if section.draft?
      section_editions.where(
        :slug => section.slug,
        :section_id.ne => section.id,
        :state => "published"
      ).empty?
    else
      true
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

  def count
    section_editions.distinct(:section_id).count
  end

private

  attr_reader(
    :manual,
  )

  def section_editions
    SectionEdition.all
  end
end
