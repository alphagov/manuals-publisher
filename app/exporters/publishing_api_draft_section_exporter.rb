require "adapters"

class PublishingApiDraftSectionExporter
  def call(section, manual)
    organisation = Adapters.organisations.find(manual.organisation_slug)

    SectionPublishingAPILinksExporter.new(organisation, manual, section).call
    SectionPublishingAPIExporter.new(organisation, manual, section).call
  end
end
