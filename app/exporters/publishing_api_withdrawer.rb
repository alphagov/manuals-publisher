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
    if entity.is_a?(Section)
      entity.uuid
    else
      entity.id
    end
  end

  def exportable_attributes
    {
      type: "gone",
    }
  end
end
