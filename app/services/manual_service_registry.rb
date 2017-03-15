class ManualServiceRegistry < AbstractManualServiceRegistry
  def associationless_repository
    RepositoryRegistry.create
      .associationless_manual_repository
  end
end
