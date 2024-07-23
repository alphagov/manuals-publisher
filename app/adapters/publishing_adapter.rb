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
end
