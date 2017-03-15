class AbstractSectionServiceRegistry
  def manual_repository
    raise NotImplementedError
  end

  def organisation(slug)
    OrganisationFetcher.instance.call(slug)
  end
end
