require "adapters"

class PublishingAdapter
  def save(manual, republish: false, include_sections: true)
    update_type = (republish ? "republish" : nil)

    organisation = organisation_for(manual)

    Services.publishing_api.patch_links(
      manual.id,
      links: {
        organisations: [organisation.content_id],
        sections: manual.sections.map(&:uuid),
      }
    )

    ManualPublishingAPIExporter.new(
      organisation, manual, update_type: update_type
    ).call

    if include_sections
      manual.sections.each do |section|
        next if !section.needs_exporting? && !republish

        save_section(section, manual, update_type: update_type)
      end
    end
  end

  def save_section(section, manual, update_type: nil)
    organisation = organisation_for(manual)

    SectionPublishingAPILinksExporter.new(
      organisation, manual, section
    ).call

    SectionPublishingAPIExporter.new(
      organisation, manual, section, update_type: update_type
    ).call
  end

private

  def organisation_for(manual)
    Adapters.organisations.find(manual.organisation_slug)
  end
end
