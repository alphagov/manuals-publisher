require "securerandom"

class ManualBuilder
  def self.create
    ManualBuilder.new(
      slug_generator: SlugGenerator.new(prefix: "guidance"),
      factory: ManualsPublisherWiring.get(:validatable_manual_with_sections_factory),
    )
  end

  def initialize(slug_generator:, factory:)
    @slug_generator = slug_generator
    @factory = factory
  end

  def call(attrs)
    @attrs = attrs

    factory.call(defaults.merge(attrs))
  end

  private

  attr_reader :slug_generator, :factory, :attrs

  def defaults
    {
      id: SecureRandom.uuid,
      slug: slug,
      summary: "",
      body: "",
      state: "draft",
      organisation_slug: "",
      updated_at: "",
      originally_published_at: nil,
      use_originally_published_at_for_public_timestamp: true,
    }
  end

  def slug
    slug_generator.call(attrs.fetch(:title))
  end
end
