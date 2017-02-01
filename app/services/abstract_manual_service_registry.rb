require "list_manuals_service"
require "create_manual_service"
require "update_manual_service"
require "show_manual_service"
require "queue_publish_manual_service"
require "preview_manual_service"
require "publish_manual_service"
require "republish_manual_service"
require "withdraw_manual_service"
require "publish_manual_worker"
require "manual_observers_registry"

class AbstractManualServiceRegistry
  def list(context)
    ListManualsService.new(
      manual_repository: associationless_repository,
      context: context,
    )
  end

  def new(context)
    ->() { manual_builder.call(title: "") }
  end

  def create(attributes)
    CreateManualService.new(
      manual_repository: repository,
      manual_builder: manual_builder,
      listeners: observers.creation,
      attributes: attributes,
    )
  end

  def update(manual_id, attributes)
    UpdateManualService.new(
      manual_repository: repository,
      manual_id: manual_id,
      attributes: attributes,
      listeners: observers.update,
    )
  end

  def show(manual_id)
    ShowManualService.new(
      manual_repository: repository,
      manual_id: manual_id,
    )
  end

  def queue_publish(manual_id)
    QueuePublishManualService.new(
      PublishManualWorker,
      repository,
      manual_id,
    )
  end

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
      manual_repository: repository,
      listeners: observers.republication,
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

  def update_original_publication_date(manual_id, attributes)
    UpdateManualOriginalPublicationDateService.new(
      manual_repository: repository,
      manual_id: manual_id,
      attributes: attributes,
      listeners: observers.update_original_publication_date,
    )
  end

private
  def manual_renderer
    ManualRenderer.create
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
