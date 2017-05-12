require "services"
require "adapters"
require "securerandom"
require "gds_api_constants"

class PublishingAdapter
  def save(manual, republish: false, include_sections: true, include_links: true)
    update_type = (republish ? GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE : nil)

    save_manual_links(manual) if include_links
    save_manual_content(manual, update_type: update_type)

    if include_sections
      manual.sections.each do |section|
        if section.needs_exporting? || republish
          save_section(section, manual, update_type: update_type, include_links: include_links)
        end
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
    update_type = (republish ? GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE : nil)
    Services.publishing_api.publish(manual.id, update_type)

    manual.sections.each do |section|
      next if !section.needs_exporting? && !republish

      Services.publishing_api.publish(section.uuid, update_type)

      section.mark_as_exported! if !republish
    end

    manual.removed_sections.each do |section|
      next if section.withdrawn? && !republish
      begin
        Services.publishing_api.unpublish(section.uuid, type: "redirect", alternative_path: "/#{manual.slug}", discard_drafts: true)
      rescue GdsApi::HTTPNotFound # rubocop:disable Lint/HandleExceptions
      end
      section.withdraw_and_mark_as_exported! if !republish
    end
  end

  def save_section(section, manual, update_type: nil, include_links: true)
    save_section_links(section, manual) if include_links
    save_section_content(section, manual, update_type: update_type)
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

    Services.publishing_api.patch_links(
      section.uuid,
      links: {
        organisations: [organisation.content_id],
        manual: [manual.id],
      }
    )
  end

  def save_section_content(section, manual, update_type: nil)
    organisation = organisation_for(manual)

    SectionPublishingAPIExporter.new(
      organisation, manual, section, update_type: update_type
    ).call
  end
end
