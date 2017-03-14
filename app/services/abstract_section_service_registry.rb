require "services"

class AbstractSectionServiceRegistry
  def manual_repository
    raise NotImplementedError
  end

  def organisation(slug)
    OrganisationFetcher.instance.call(slug)
  end

  def publishing_api_draft_section_discarder
    PublishingApiDraftSectionDiscarder.new(self)
  end

  def publishing_api_v2
    Services.publishing_api_v2
  end

  def organisations_api
    Services.organisations
  end
end
