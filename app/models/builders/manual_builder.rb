require "securerandom"

class ManualBuilder
  def call(attrs)
    slug_generator = SlugGenerator.new(prefix: "guidance")

    default_attrs = {
      id: SecureRandom.uuid,
      slug: slug_generator.call(attrs.fetch(:title)),
      summary: "",
      body: "",
      state: "draft",
      organisation_slug: "",
      updated_at: "",
      originally_published_at: nil,
      use_originally_published_at_for_public_timestamp: true,
    }

    manual_attrs = default_attrs.merge(attrs)
    manual = Manual.new(manual_attrs)
    manual.sections = manual_attrs.fetch(:sections, [])
    manual.removed_sections = manual_attrs.fetch(:removed_sections, [])
    manual
  end
end
