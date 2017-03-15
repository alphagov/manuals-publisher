class PublishingApiDraftSectionDiscarder
  def call(section, _manual)
    Services.publishing_api_v2.discard_draft(section.id)
  rescue GdsApi::HTTPNotFound, GdsApi::HTTPUnprocessableEntity # rubocop:disable Lint/HandleExceptions
  end
end
