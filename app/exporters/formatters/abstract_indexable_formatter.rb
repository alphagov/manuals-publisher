class AbstractIndexableFormatter
  def type
    raise NotImplementedError
  end

  def indexable_attributes
    raise NotImplementedError
  end

private

  def root_path
    Pathname.new('/')
  end
end
