require "services"
require "gds_api_constants"

class PublishingApiManualWithSectionsPublisher
  def call(manual, action = nil)
    update_type = (action == :republish ? GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE : nil)
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
        Services.publishing_api.unpublish(section.uuid, type: "redirect", alternative_path: "/#{manual.slug}", discard_drafts: true)
      rescue GdsApi::HTTPNotFound # rubocop:disable Lint/HandleExceptions
      end
      section.withdraw_and_mark_as_exported! if action != :republish
    end
  end
end
