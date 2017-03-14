class PublishingApiDraftSectionDiscarder
  def initialize(services)
    @services = services
  end

  def call(section, _manual)
    @services.publishing_api_v2.discard_draft(section.id)
  rescue GdsApi::HTTPNotFound, GdsApi::HTTPUnprocessableEntity # rubocop:disable Lint/HandleExceptions
  end
end
