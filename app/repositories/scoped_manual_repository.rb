class ScopedManualRepository
  extend Forwardable

  def_delegators :@repository, :all, :store, :[], :fetch, :slug_unique?

  def initialize(collection)
    @repository = ManualRepository.new(
      association_marshallers: [
        SectionAssociationMarshaller.new,
        ManualPublishTaskAssociationMarshaller.new
      ],
      collection: collection,
    )
  end
end
