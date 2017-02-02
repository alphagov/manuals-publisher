class PublishingAPIPublisher
  UPDATE_TYPES = %w(minor major republish).freeze

  def initialize(publishing_api:, entity:, update_type: nil)
    @publishing_api = publishing_api
    @entity = entity
    @update_type = update_type
    raise ArgumentError, "update_type '#{update_type}' not recognised" if update_type.present? && !UPDATE_TYPES.include?(update_type)
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
