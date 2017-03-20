class PublishingAPIWithdrawer
  def initialize(entity:)
    @publishing_api = Services.publishing_api_v2
    @entity = entity
  end

  def call
    publishing_api.unpublish(content_id, exportable_attributes)
  end

private

  attr_reader(
    :publishing_api,
    :entity,
  )

  def content_id
    entity.id
  end

  def exportable_attributes
    {
      type: "gone",
    }
  end
end
