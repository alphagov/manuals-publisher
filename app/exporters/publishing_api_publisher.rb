class PublishingAPIPublisher
  def initialize(publishing_api:, entity:)
    @publishing_api = publishing_api
    @entity = entity
  end

  def call
    publishing_api.publish(entity.id, nil)
  end

private

  attr_reader(
    :publishing_api,
    :entity,
  )
end
