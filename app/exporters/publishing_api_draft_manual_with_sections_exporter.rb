class PublishingApiDraftManualWithSectionsExporter
  def call(manual, action = nil)
    update_type = (action == :republish ? "republish" : nil)

    organisation = organisation(manual.attributes.fetch(:organisation_slug))

    ManualPublishingAPILinksExporter.new(
      organisation, manual
    ).call

    ManualPublishingAPIExporter.new(
      organisation, manual, update_type: update_type
    ).call

    manual.sections.each do |section|
      next if !section.needs_exporting? && action != :republish

      SectionPublishingAPILinksExporter.new(
        organisation, manual, section
      ).call

      SectionPublishingAPIExporter.new(
        organisation, manual, section, update_type: update_type
      ).call
    end
  end

  def organisation(slug)
    OrganisationFetcher.fetch(slug)
  end
end
