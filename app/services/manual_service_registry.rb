class ManualServiceRegistry < AbstractManualServiceRegistry

private
  def associationless_repository
    ManualsPublisherWiring.get(:repository_registry)
      .associationless_manual_repository
  end

  def repository
    ManualsPublisherWiring.get(:repository_registry).manual_repository
  end
end
