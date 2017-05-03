class AbstractIndexableFormatter
  def initialize(entity)
    @entity = entity
  end

  def type
    raise NotImplementedError
  end

  def id
    link
  end

  def indexable_attributes
    raise NotImplementedError
  end

private

  attr_reader :entity

  def link
    with_leading_slash(entity.slug)
  end

  def with_leading_slash(slug)
    slug.start_with?("/") ? slug : "/#{slug}"
  end

  def public_timestamp
    entity.updated_at
  end
end
