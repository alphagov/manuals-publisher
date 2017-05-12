require "services"

class PublishingAPIPublisher
  def call(entity:, update_type: nil)
    entity_id = entity.is_a?(Section) ? entity.uuid : entity.id
    Services.publishing_api.publish(entity_id, update_type)
  end
end
