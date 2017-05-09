require "adapters"

class PublishingAdapter
  def save(manual, republish: false)
    update_type = (republish ? "republish" : nil)

    organisation = Adapters.organisations.find(manual.organisation_slug)

    ManualPublishingAPILinksExporter.new.call(
      organisation, manual
    )

    ManualPublishingAPIExporter.new(
      organisation, manual, update_type: update_type
    ).call

    manual.sections.each do |section|
      next if !section.needs_exporting? && !republish

      SectionPublishingAPILinksExporter.new(
        organisation, manual, section
      ).call

      SectionPublishingAPIExporter.new(
        organisation, manual, section, update_type: update_type
      ).call
    end
  end
end
