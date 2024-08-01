class Publishing::UnpublishAdapter
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
      unpublish_and_redirect_section(section, redirect:, discard_drafts:)
    end
  end

  def self.unpublish_and_redirect_section(section, redirect:, republish: false, discard_drafts: true)
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
end
