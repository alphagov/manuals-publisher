class ScopedManualRepository
  extend Forwardable

  def_delegators :@repository, :all, :store, :[], :fetch, :slug_unique?

  def initialize(collection)
    @repository = ManualRepository.new(
      association_marshallers: [
        SectionAssociationMarshaller.new(
          decorator: ->(manual, attrs) {
            ManualValidator.new(
              NullValidator.new(
                ManualWithSections.new(
                  SectionBuilder.new,
                  manual,
                  attrs,
                )
              )
            )
          }
        ),
        ManualPublishTaskAssociationMarshaller.new
      ],
      collection: collection,
    )
  end
end
