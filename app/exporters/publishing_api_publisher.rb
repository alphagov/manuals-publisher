class PublishingAPIPublisher
  include PublishingAPIUpdateTypes

  def initialize(entity:, update_type: nil)
    @entity = entity
    @update_type = update_type
    check_update_type!(@update_type)
  end

  def call
    Services.publishing_api.publish(entity.id, update_type)
  end

private

  attr_reader(
    :entity,
    :update_type,
  )
end
