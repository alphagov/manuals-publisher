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
    @section_factory = SectionFactory.new(manual)
  end

  def all(limit = -1, offset = 0)
    lower_bound = offset
    upper_bound = limit < 0 ? limit : offset + limit - 1

    all_section_ids[lower_bound..upper_bound]
      .map { |id| self[id] }
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
      section_factory.call(id, editions)
    end
  end

  def search(query)
    conditions = search_conditions(query)

    all_section_ids_scoped(conditions)
      .map { |id| fetch(id) }
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
    :section_factory,
  )

  def search_conditions(query)
    matcher = /#{query}/i
    searchable_attributes.map { |attr|
      { attr => matcher }
    }
  end

  def searchable_attributes
    [
      :title,
      :slug,
    ]
  end

  def all_section_ids_scoped(conditions)
    only_section_ids_for(
      section_editions
        .any_of(conditions)
    )
  end

  def only_section_ids_for(collection)
    collection.all
      .order_by([:updated_at, :desc])
      .only(:section_id, :updated_at)
      .map(&:section_id)
      .uniq
  end

  def all_section_ids
    only_section_ids_for(
      section_editions
        .all
    )
  end

  def section_editions
    SectionEdition.all
  end
end
