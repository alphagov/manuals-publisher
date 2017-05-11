require "services"

class PublishingAPIWithdrawer
  def initialize(entity:)
    @entity = entity
  end

  def call
    content_id = entity.is_a?(Section) ? entity.uuid : entity.id
    Services.publishing_api.unpublish(content_id, exportable_attributes)
  end

private

  attr_reader(
    :entity,
  )

  def exportable_attributes
    {
      type: "gone",
    }
  end
end
