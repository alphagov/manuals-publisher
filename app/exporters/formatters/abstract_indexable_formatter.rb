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

  def root_path
    Pathname.new('/')
  end
end
