class PublishingAPIPublisher
  include PublishingAPIUpdateTypes

  def initialize(entity:, update_type: nil)
    @publishing_api = Services.publishing_api_v2
    @entity = entity
    @update_type = update_type
    check_update_type!(@update_type)
  end

  def call
    publishing_api.publish(entity.id, update_type)
  end

private

  attr_reader(
    :publishing_api,
    :entity,
    :update_type,
  )
end
