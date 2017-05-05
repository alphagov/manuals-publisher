class PublishingAPIPublisher
  include PublishingAPIUpdateTypes

  def initialize(entity:, update_type: nil)
    @entity = entity
    @update_type = update_type
    check_update_type!(@update_type)
  end

  def call
    Services.publishing_api.publish(entity_id, update_type)
  end

private

  def entity_id
    if entity.is_a?(Section)
      entity.uuid
    else
      entity.id
    end
  end

  attr_reader(
    :entity,
    :update_type,
  )
end
