class SectionServiceRegistry < AbstractSectionServiceRegistry
private

  def manual_repository
    RepositoryRegistry.create.manual_repository
  end
end
