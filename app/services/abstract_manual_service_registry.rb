require "manual_observers_registry"
require "builders/manual_builder"

class AbstractManualServiceRegistry
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
