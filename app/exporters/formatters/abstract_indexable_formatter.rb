class AbstractIndexableFormatter
  def type
    raise NotImplementedError
  end

  def indexable_attributes
    raise NotImplementedError
  end
end
