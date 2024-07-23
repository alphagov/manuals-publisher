class Publishing::DraftAdapter
  def self.save_draft_for_manual_and_sections(manual, republish: false, include_sections: true, include_links: true)
    save_draft_for_manual(manual, republish:, include_links:)

    if include_sections
      manual.sections.each do |section|
        save_draft_for_section(section, manual, republish:, include_links:)
      end
    end
  end

  def self.save_draft_for_section(section, manual, republish: false, include_links: true)
    if section.needs_exporting? || republish
      patch_links_for_section(section, manual) if include_links
      put_content_for_section(section, manual, republish:)
    end
  end

  def self.discard_draft_for_manual(manual)
    manual.sections.each do |section|
      discard_draft_for_section(section)
    end
    Services.publishing_api.discard_draft(manual.id)
  end

  def self.discard_draft_for_section(section)
    Services.publishing_api.discard_draft(section.uuid)
  end

  private_class_method def self.save_draft_for_manual(manual, republish:, include_links:)
    patch_links_for_manual(manual) if include_links
    put_content_for_manual(manual, republish:)
  end

  private_class_method def self.patch_links_for_manual(manual)
    organisation = OrganisationsAdapter.find(manual.organisation_slug)

    Services.publishing_api.patch_links(
      manual.id,
      links: {
        organisations: [organisation.content_id],
        primary_publishing_organisation: [organisation.content_id],
        sections: manual.sections.map(&:uuid),
      },
    )
  end

  private_class_method def self.put_content_for_manual(manual, republish: false)
    organisation = OrganisationsAdapter.find(manual.organisation_slug)

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
      base_path:,
      schema_name: GdsApiConstants::PublishingApi::MANUAL_SCHEMA_NAME,
      document_type: GdsApiConstants::PublishingApi::MANUAL_DOCUMENT_TYPE,
      title: manual.title,
      description: manual.summary,
      update_type:,
      bulk_publishing: republish,
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

  private_class_method def self.patch_links_for_section(section, manual)
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

  private_class_method def self.put_content_for_section(section, manual, republish: false)
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

  private_class_method def self.version_type(republish)
    republish ? :republish : nil
  end
end
