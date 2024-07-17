require "securerandom"

class PublishingAdapter
  def self.unpublish_and_redirect_manual_and_sections(manual, redirect:, discard_drafts:)
    Services.publishing_api.unpublish(
      manual.id,
      type: "redirect",
      redirects: [
        { path: "/#{manual.slug}", type: "exact", destination: redirect },
        { path: "/#{manual.slug}/updates", type: "exact", destination: redirect },
      ],
      discard_drafts:,
    )

    manual.sections.each do |section|
      unpublish_section(section, redirect:, discard_drafts:)
    end
  end

  def self.unpublish_section(section, redirect:, republish: false, discard_drafts: true)
    if !section.withdrawn? || republish
      begin
        Services.publishing_api.unpublish(
          section.uuid, type: "redirect", alternative_path: redirect, discard_drafts:
        )
        section.withdraw_and_mark_as_exported! unless republish
      rescue GdsApi::HTTPNotFound
        Rails.logger.warn "Content item with section uuid #{section.uuid} not present in the publishing API"
      end
    end
  end

  def self.unpublish(manual)
    Services.publishing_api.unpublish(manual.id, type: "gone")

    manual.sections.each do |section|
      Services.publishing_api.unpublish(section.uuid, type: "gone")
    end
  end

  def self.publish(manual, republish: false)
    publish_manual(manual, republish:)

    manual.sections.each do |section|
      publish_section(section, republish:)
    end

    manual.removed_sections.each do |section|
      unpublish_section(section, redirect: "/#{manual.slug}", republish:)
    end
  end

  def self.discard(manual)
    manual.sections.each do |section|
      discard_section(section)
    end
    Services.publishing_api.discard_draft(manual.id)
  end

  def self.save_section(section, manual, republish: false, include_links: true)
    if section.needs_exporting? || republish
      save_section_links(section, manual) if include_links
      save_section_content(section, manual, republish:)
    end
  end

  def self.redirect_section(section, to:)
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

  def self.discard_section(section)
    Services.publishing_api.discard_draft(section.uuid)
  end

  def self.publish_manual(manual, republish:)
    Services.publishing_api.publish(manual.id, update_type(republish))
  end

  def self.save_section_links(section, manual)
    organisation = OrganisationsAdapter.find(manual.organisation_slug)

    Services.publishing_api.patch_links(
      section.uuid,
      links: {
        organisations: [organisation.content_id],
        primary_publishing_organisation: [organisation.content_id],
        manual: [manual.id],
      },
    )
  end

  def self.save_section_content(section, manual, republish: false)
    organisation = OrganisationsAdapter.find(manual.organisation_slug)

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
      update_type:,
      bulk_publishing: republish,
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
        visually_expanded: section.visually_expanded,
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

  def self.publish_section(section, republish:)
    if section.needs_exporting? || republish
      Services.publishing_api.publish(section.uuid, update_type(republish))
      section.mark_as_exported! unless republish
    end
  end

  def self.update_type(republish)
    republish ? GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE : nil
  end

  def self.version_type(republish)
    republish ? :republish : nil
  end
end
