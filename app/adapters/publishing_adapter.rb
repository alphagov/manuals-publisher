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

  def discard(manual)
    manual.sections.each do |section|
      discard_section(section)
    end
    Services.publishing_api.discard_draft(manual.id)
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
      document_type: "redirect",
      schema_name: "redirect",
      publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
      base_path: "/#{section.slug}",
      redirects: [
        {
          path: "/#{section.slug}",
          type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
          destination: to,
        },
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
    save_manual_content(manual, republish: republish)
  end

  def save_manual_links(manual)
    organisation = organisation_for(manual)

    Services.publishing_api.patch_links(
      manual.id,
      links: {
        organisations: [organisation.content_id],
        primary_publishing_organisation: [organisation.content_id],
        sections: manual.sections.map(&:uuid),
      },
    )
  end

  def save_manual_content(manual, republish: false)
    organisation = organisation_for(manual)

    update_type = case version_type(republish) || manual.version_type
                  when :new, :major
                    GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE
                  when :minor
                    GdsApiConstants::PublishingApi::MINOR_UPDATE_TYPE
                  when :republish
                    GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE
                  else
                    raise "Uknown version type: #{manual.version_type}"
                  end

    base_path = "/#{manual.slug}"
    updates_path = [base_path, GdsApiConstants::PublishingApi::UPDATES_PATH_SUFFIX].join("/")

    attributes = {
      base_path: base_path,
      schema_name: GdsApiConstants::PublishingApi::MANUAL_SCHEMA_NAME,
      document_type: GdsApiConstants::PublishingApi::MANUAL_DOCUMENT_TYPE,
      title: manual.title,
      description: manual.summary,
      update_type: update_type,
      publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
      rendering_app: GdsApiConstants::PublishingApi::RENDERING_APP,
      routes: [
        {
          path: base_path,
          type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
        },
        {
          path: updates_path,
          type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
        },
      ],
      details: {
        body: [
          {
            content_type: "text/govspeak",
            content: manual.body,
          },
          {
            content_type: "text/html",
            content: ManualPresenter.new(manual).body,
          },
        ],
        child_section_groups: [
          {
            title: GdsApiConstants::PublishingApi::CHILD_SECTION_GROUP_TITLE,
            child_sections: manual.sections.map do |section|
              {
                title: section.title,
                description: section.summary,
                base_path: "/#{section.slug}",
              }
            end,
          },
        ],
        change_notes: manual.publication_logs.map do |publication_log|
          {
            base_path: "/#{publication_log.slug}",
            title: publication_log.title,
            change_note: publication_log.change_note,
            published_at: publication_log.published_at,
          }
        end,
        organisations: [
          {
            title: organisation.title,
            abbreviation: organisation.abbreviation || "",
            web_url: organisation.web_url,
          },
        ],
      },
      locale: GdsApiConstants::PublishingApi::EDITION_LOCALE,
    }

    latest_publication = manual.publication_logs.last
    if latest_publication
      attributes[:change_note] = "#{latest_publication.title} - #{latest_publication.change_note}"
    end

    if manual.originally_published_at.present?
      attributes[:first_published_at] = manual.originally_published_at
      if manual.use_originally_published_at_for_public_timestamp?
        attributes[:public_updated_at] = manual.originally_published_at
      end
    end

    Services.publishing_api.put_content(manual.id, attributes)
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
        primary_publishing_organisation: [organisation.content_id],
        manual: [manual.id],
      },
    )
  end

  def save_section_content(section, manual, republish: false)
    organisation = organisation_for(manual)

    update_type = case version_type(republish) || section.version_type
                  when :new, :major
                    GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE
                  when :minor
                    GdsApiConstants::PublishingApi::MINOR_UPDATE_TYPE
                  when :republish
                    GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE
                  else
                    raise "Unknown version type: #{section.version_type}"
                  end

    attributes = {
      base_path: "/#{section.slug}",
      schema_name: GdsApiConstants::PublishingApi::SECTION_SCHEMA_NAME,
      document_type: GdsApiConstants::PublishingApi::SECTION_DOCUMENT_TYPE,
      title: section.title,
      description: section.summary,
      update_type: update_type,
      publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
      rendering_app: GdsApiConstants::PublishingApi::RENDERING_APP,
      change_note: section.change_note,
      routes: [
        {
          path: "/#{section.slug}",
          type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
        },
      ],
      details: {
        body: [
          {
            content_type: "text/govspeak",
            content: section.body,
          },
          {
            content_type: "text/html",
            content: SectionPresenter.new(section).body,
          },
        ],
        attachments: section.attachments.map do |attachment|
          {
            attachment_type: "file",
            id: SecureRandom.uuid,
            title: attachment.title,
            url: attachment.file_url,
            content_type: attachment.content_type,
          }
        end,
        manual: {
          base_path: "/#{manual.slug}",
        },
        organisations: [
          {
            title: organisation.title,
            abbreviation: organisation.abbreviation || "",
            web_url: organisation.web_url,
          },
        ],
      },
      locale: GdsApiConstants::PublishingApi::EDITION_LOCALE,
    }

    if manual.originally_published_at.present?
      attributes[:first_published_at] = manual.originally_published_at
      if manual.use_originally_published_at_for_public_timestamp?
        attributes[:public_updated_at] = manual.originally_published_at
      end
    end

    Services.publishing_api.put_content(section.uuid, attributes)
  end

  def publish_section(section, republish:)
    if section.needs_exporting? || republish
      Services.publishing_api.publish(section.uuid, update_type(republish))
      section.mark_as_exported! unless republish
    end
  end

  def unpublish_section(section, manual, republish:)
    if !section.withdrawn? || republish
      begin
        Services.publishing_api.unpublish(section.uuid, type: "redirect", alternative_path: "/#{manual.slug}", discard_drafts: true)
        section.withdraw_and_mark_as_exported! unless republish
      rescue GdsApi::HTTPNotFound
        Rails.logger.warn "Content item with section uuid #{section.uuid} not present in the publishing API"
      end
    end
  end

  def update_type(republish)
    republish ? GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE : nil
  end

  def version_type(republish)
    republish ? :republish : nil
  end
end
