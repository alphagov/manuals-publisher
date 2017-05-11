require "services"

class PublishingAPIPublisher
  include PublishingAPIUpdateTypes

  def call(entity:, update_type: nil)
    check_update_type!(update_type)
    entity_id = entity.is_a?(Section) ? entity.uuid : entity.id
    Services.publishing_api.publish(entity_id, update_type)
  end
end
