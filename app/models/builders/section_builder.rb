require "securerandom"

class SectionBuilder
  def call(manual, attrs)
    section_factory = SectionFactory.new(manual)
    section = section_factory.call(SecureRandom.uuid, [])

    section.update(attrs.reverse_merge(defaults))

    section
  end

private

  def defaults
    {
      minor_update: false,
      change_note: "New section added.",
    }
  end
end
