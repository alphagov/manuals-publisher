require "adapters"

class PublishingAdapter
  def save(manual, republish: false, include_sections: true)
    update_type = (republish ? "republish" : nil)

    save_manual_links(manual)
    save_manual_content(manual, update_type: update_type)

    if include_sections
      manual.sections.each do |section|
        if section.needs_exporting? || republish
          save_section(section, manual, update_type: update_type)
        end
      end
    end
  end

  def save_section(section, manual, update_type: nil)
    save_section_links(section, manual)
    save_section_content(section, manual, update_type: update_type)
  end

private

  def organisation_for(manual)
    Adapters.organisations.find(manual.organisation_slug)
  end

  def save_manual_links(manual)
    organisation = organisation_for(manual)

    Services.publishing_api.patch_links(
      manual.id,
      links: {
        organisations: [organisation.content_id],
        sections: manual.sections.map(&:uuid),
      }
    )
  end

  def save_manual_content(manual, update_type: nil)
    organisation = organisation_for(manual)

    ManualPublishingAPIExporter.new(
      organisation, manual, update_type: update_type
    ).call
  end

  def save_section_links(section, manual)
    organisation = organisation_for(manual)

    SectionPublishingAPILinksExporter.new(
      organisation, manual, section
    ).call
  end

  def save_section_content(section, manual, update_type: nil)
    organisation = organisation_for(manual)

    SectionPublishingAPIExporter.new(
      organisation, manual, section, update_type: update_type
    ).call
  end
end
