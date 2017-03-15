require "preview_manual_service"
require "publish_manual_service"
require "republish_manual_service"
require "withdraw_manual_service"
require "manual_observers_registry"
require "builders/manual_builder"

class AbstractManualServiceRegistry
  def preview(manual_id, attributes)
    PreviewManualService.new(
      repository: repository,
      builder: manual_builder,
      renderer: manual_renderer,
      manual_id: manual_id,
      attributes: attributes,
    )
  end

  def publish(manual_id, version_number)
    PublishManualService.new(
      manual_repository: repository,
      listeners: observers.publication,
      manual_id: manual_id,
      version_number: version_number,
    )
  end

  def republish(manual_id)
    RepublishManualService.new(
      draft_listeners: observers.update,
      published_listeners: observers.republication,
      manual_id: manual_id,
    )
  end

  def withdraw(manual_id)
    WithdrawManualService.new(
      manual_repository: repository,
      listeners: observers.withdrawal,
      manual_id: manual_id,
    )
  end

  def manual_renderer
    ManualRenderer.new
  end

  def manual_builder
    ManualBuilder.create
  end

  def repository
    raise NotImplementedError
  end

  def associationless_repository
    raise NotImplementedError
  end

  def observers
    @observers ||= ManualObserversRegistry.new
  end
end
