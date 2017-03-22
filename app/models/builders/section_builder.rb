require "securerandom"

class SectionBuilder
  def call(manual, attrs)
    section_factory = SectionFactory.new(manual)
    document = section_factory.call(SecureRandom.uuid, [])

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
