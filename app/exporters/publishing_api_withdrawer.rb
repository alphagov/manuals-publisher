class PublishingAPIWithdrawer
  def initialize(entity:)
    @entity = entity
  end

  def call
    Services.publishing_api.unpublish(content_id, exportable_attributes)
  end

private

  attr_reader(
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
