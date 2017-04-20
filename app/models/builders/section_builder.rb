require "securerandom"

class SectionBuilder
  def call(manual, attrs)
    section_factory = SectionFactory.new(manual)
    section = section_factory.call(SecureRandom.uuid, [])

    defaults = {
      minor_update: false,
      change_note: "New section added.",
    }
    section.update(attrs.reverse_merge(defaults))

    section
  end
end
