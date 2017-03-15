require "securerandom"

class SectionBuilder
  def self.create
    DocumentFactoryRegistry.validatable_document_factories.manual_document_builder
  end

  def initialize(factory_factory:)
    @factory_factory = factory_factory
  end

  def call(manual, attrs)
    document = @factory_factory
      .call(manual)
      .call(SecureRandom.uuid, [])

    document.update(attrs.reverse_merge(defaults))

    document
  end

private

  def defaults
    {
      minor_update: false,
      change_note: "New section added.",
    }
  end
end
