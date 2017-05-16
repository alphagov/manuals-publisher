require "services"
require "adapters"
require "securerandom"
require "gds_api_constants"

class PublishingAdapter
  def save(manual, republish: false, include_sections: true, include_links: true)
    save_manual(manual, republish: republish, include_links: include_links)

    if include_sections
      manual.sections.each do |section|
        save_section(section, manual, republish: republish, include_links: include_links)
      end
    end
  end

  def unpublish(manual)
    Services.publishing_api.unpublish(manual.id, type: "gone")

    manual.sections.each do |section|
      Services.publishing_api.unpublish(section.uuid, type: "gone")
    end
  end

  def publish(manual, republish: false)
    publish_manual(manual, republish: republish)

    manual.sections.each do |section|
      publish_section(section, republish: republish)
    end

    manual.removed_sections.each do |section|
      unpublish_section(section, manual, republish: republish)
    end
  end

  def save_section(section, manual, republish: false, include_links: true)
    if section.needs_exporting? || republish
      save_section_links(section, manual) if include_links
      save_section_content(section, manual, republish: republish)
    end
  end

  def redirect_section(section, to:)
    Services.publishing_api.put_content(
      SecureRandom.uuid,
      document_type: 'redirect',
      schema_name: 'redirect',
      publishing_app: GdsApiConstants::PublishingApiV2::PUBLISHING_APP,
      base_path: "/#{section.slug}",
      redirects: [
        {
          path: "/#{section.slug}",
          type: GdsApiConstants::PublishingApiV2::EXACT_ROUTE_TYPE,
          destination: to
        }
      ],
    )
  end

  def discard_section(section)
    Services.publishing_api.discard_draft(section.uuid)
  end

private

  def organisation_for(manual)
    Adapters.organisations.find(manual.organisation_slug)
  end

  def save_manual(manual, republish:, include_links:)
    save_manual_links(manual) if include_links
    save_manual_content(manual, update_type: update_type(republish))
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

  def publish_manual(manual, republish:)
    Services.publishing_api.publish(manual.id, update_type(republish))
  end

  def save_section_links(section, manual)
    organisation = organisation_for(manual)

    Services.publishing_api.patch_links(
      section.uuid,
      links: {
        organisations: [organisation.content_id],
        manual: [manual.id],
      }
    )
  end

  def save_section_content(section, manual, republish: false)
    organisation = organisation_for(manual)

    SectionPublishingAPIExporter.new.call(
      organisation, manual, section, version_type: version_type(republish)
    )
  end

  def publish_section(section, republish:)
    if section.needs_exporting? || republish
      Services.publishing_api.publish(section.uuid, update_type(republish))
      section.mark_as_exported! if !republish
    end
  end

  def unpublish_section(section, manual, republish:)
    if !section.withdrawn? || republish
      Services.publishing_api.unpublish(section.uuid, type: "redirect", alternative_path: "/#{manual.slug}", discard_drafts: true)
      section.withdraw_and_mark_as_exported! if !republish
    end
  end

  def update_type(republish)
    republish ? GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE : nil
  end

  def version_type(republish)
    republish ? :republish : nil
  end
end
