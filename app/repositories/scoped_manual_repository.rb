class ScopedManualRepository
  extend Forwardable

  def_delegators :@repository, :all, :store, :[], :fetch, :slug_unique?

  def initialize(collection)
    @repository = ManualRepository.new(
      collection: collection,
    )
  end
end
