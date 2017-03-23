class PublishingApiManualWithSectionsPublisher
  def call(manual, action = nil)
    update_type = (action == :republish ? "republish" : nil)
    PublishingAPIPublisher.new(
      entity: manual,
      update_type: update_type,
    ).call

    manual.sections.each do |section|
      next if !section.needs_exporting? && action != :republish

      PublishingAPIPublisher.new(
        entity: section,
        update_type: update_type,
      ).call

      section.mark_as_exported! if action != :republish
    end

    manual.removed_sections.each do |section|
      next if section.withdrawn? && action != :republish
      begin
        publishing_api_v2.unpublish(section.id, type: "redirect", alternative_path: "/#{manual.slug}", discard_drafts: true)
      rescue GdsApi::HTTPNotFound # rubocop:disable Lint/HandleExceptions
      end
      section.withdraw_and_mark_as_exported! if action != :republish
    end
  end

  def publishing_api_v2
    Services.publishing_api_v2
  end
end
