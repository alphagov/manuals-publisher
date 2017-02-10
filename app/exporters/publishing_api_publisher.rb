class PublishingAPIPublisher
  include PublishingAPIUpdateTypes

  def initialize(publishing_api:, entity:, update_type: nil)
    @publishing_api = publishing_api
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
