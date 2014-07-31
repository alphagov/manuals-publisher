class ManualWorkersRegistry

  def publish(id)
    PublishManualWorker.perform_async(id)
  end
end
