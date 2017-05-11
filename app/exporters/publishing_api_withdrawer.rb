require "services"

class PublishingAPIWithdrawer
  def call(entity:)
    content_id = entity.is_a?(Section) ? entity.uuid : entity.id
    Services.publishing_api.unpublish(content_id, type: "gone")
  end
end
