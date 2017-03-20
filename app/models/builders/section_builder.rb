require "securerandom"

class SectionBuilder
  def call(manual, attrs)
    factory_factory = DocumentFactoryRegistry.new.section_factory_factory
    document = factory_factory
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
