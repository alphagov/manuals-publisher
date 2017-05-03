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
    root_path.join(slug).to_s
  end

  def root_path
    Pathname.new('/')
  end
end
