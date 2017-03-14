class SectionServiceRegistry < AbstractSectionServiceRegistry
  def manual_repository
    RepositoryRegistry.create.manual_repository
  end
end
