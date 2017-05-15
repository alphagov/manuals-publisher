require "services"

class PublishingApiDraftSectionDiscarder
  def call(section, _manual)
    Services.publishing_api.discard_draft(section.uuid)
  rescue GdsApi::HTTPNotFound, GdsApi::HTTPUnprocessableEntity # rubocop:disable Lint/HandleExceptions
  end
end
