class AbstractIndexableFormatter
  def initialize(entity)
    @entity = entity
  end

  def type
    raise NotImplementedError
  end

  def id
    path
  end

  def indexable_attributes
    raise NotImplementedError
  end

private

  attr_reader :entity

  def with_leading_slash(slug)
    root_path.join(slug).to_s
  end

  def root_path
    Pathname.new('/')
  end
end
