class PublishingAPIWithdrawer
  def initialize(publishing_api:, entity:)
    @publishing_api = publishing_api
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
