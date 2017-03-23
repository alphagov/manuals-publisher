class PublishingApiManualWithSectionsPublisher
  def call(manual, action = nil)
    update_type = (action == :republish ? "republish" : nil)
    PublishingAPIPublisher.new(
      entity: manual,
      update_type: update_type,
    ).call

    manual.sections.each do |document|
      next if !document.needs_exporting? && action != :republish

      PublishingAPIPublisher.new(
        entity: document,
        update_type: update_type,
      ).call

      document.mark_as_exported! if action != :republish
    end

    manual.removed_sections.each do |document|
      next if document.withdrawn? && action != :republish
      begin
        publishing_api_v2.unpublish(document.id, type: "redirect", alternative_path: "/#{manual.slug}", discard_drafts: true)
      rescue GdsApi::HTTPNotFound # rubocop:disable Lint/HandleExceptions
      end
      document.withdraw_and_mark_as_exported! if action != :republish
    end
  end

  def publishing_api_v2
    Services.publishing_api_v2
  end
end
