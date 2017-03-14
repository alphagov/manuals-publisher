require "services"

class AbstractSectionServiceRegistry
  def manual_repository
    raise NotImplementedError
  end

  def organisation(slug)
    OrganisationFetcher.instance.call(slug)
  end

  def publishing_api_draft_manual_exporter
    PublishingApiDraftManualExporter.new(self)
  end

  def publishing_api_draft_section_exporter
    ->(section, manual) {
      SectionPublishingAPILinksExporter.new(
        publishing_api_v2.method(:patch_links),
        organisation(manual.attributes.fetch(:organisation_slug)),
        manual,
        section
      ).call

      SectionPublishingAPIExporter.new(
        organisation(manual.attributes.fetch(:organisation_slug)),
        manual,
        section
      ).call
    }
  end

  def publishing_api_draft_section_discarder
    ->(section, _manual) {
      begin
        publishing_api_v2.discard_draft(section.id)
      rescue GdsApi::HTTPNotFound, GdsApi::HTTPUnprocessableEntity # rubocop:disable Lint/HandleExceptions
      end
    }
  end

  def publishing_api_v2
    Services.publishing_api_v2
  end

  def organisations_api
    Services.organisations
  end
end
