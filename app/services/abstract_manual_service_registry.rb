class AbstractManualServiceRegistry
  def repository
    raise NotImplementedError
  end

  def associationless_repository
    raise NotImplementedError
  end
end
