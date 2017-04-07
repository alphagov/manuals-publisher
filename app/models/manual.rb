class Manual
  include ActiveModel::Validations

  validates :title, presence: true
  validates :summary, presence: true
  validates :body, safe_html: true

  attr_reader(
    :id,
    :slug,
    :title,
    :summary,
    :body,
    :organisation_slug,
    :state,
    :version_number,
    :updated_at,
    :originally_published_at,
    :use_originally_published_at_for_public_timestamp,
  )

  attr_accessor :sections, :removed_sections

  NotFoundError = Module.new

  def self.find(id, user)
    ManualRepository.new(user.manual_records).fetch(id)
  rescue KeyError => e
    raise e.extend(NotFoundError)
  end

  def self.all(user, load_associations: true)
    ManualRepository.new(user.manual_records).all(load_associations: load_associations)
  end

  def self.build(attributes)
    ManualBuilder.new.call(attributes)
  end

  def slug_unique?(user)
    ManualRepository.new(user.manual_records).slug_unique?(self)
  end

  def clashing_sections
    sections
      .group_by(&:slug)
      .select { |_slug, docs| docs.size > 1 }
  end

  def save(user)
    manual = self

    manual_record = user.manual_records.find_or_initialize_by(manual_id: manual.id)
    # TODO: slug must not change after publication
    manual_record.slug = manual.slug
    manual_record.organisation_slug = manual.organisation_slug
    edition = manual_record.new_or_existing_draft_edition
    edition.attributes = {
      title: manual.title,
      summary: manual.summary,
      body: manual.body,
      state: manual.state,
      originally_published_at: manual.originally_published_at,
      use_originally_published_at_for_public_timestamp: manual.use_originally_published_at_for_public_timestamp,
    }

    section_repository = SectionRepository.new(manual: manual)

    manual.sections.each do |section|
      section_repository.store(section)
    end

    manual.removed_sections.each do |section|
      section_repository.store(section)
    end

    edition.section_ids = manual.sections.map(&:id)
    edition.removed_section_ids = manual.removed_sections.map(&:id)

    manual_record.save!
  end

  def current_versions
    repository = VersionedManualRepository.new
    repository.get_manual(id)
  end

  def initialize(attributes)
    @id = attributes.fetch(:id)
    @updated_at = attributes.fetch(:updated_at, nil)
    @version_number = attributes.fetch(:version_number, 0)
    @ever_been_published = !!attributes.fetch(:ever_been_published, false)

    update(attributes)

    @sections = []
    @removed_sections = []
    @section_builder = SectionBuilder.new
  end

  def to_param
    id
  end

  def eql?(other)
    id.eql? other.id
  end

  def attributes
    {
      id: id,
      slug: slug,
      title: title,
      summary: summary,
      body: body,
      organisation_slug: organisation_slug,
      state: state,
      version_number: version_number,
      updated_at: updated_at,
      originally_published_at: originally_published_at,
      use_originally_published_at_for_public_timestamp: use_originally_published_at_for_public_timestamp,
    }
  end

  def update(attributes)
    @slug = attributes.fetch(:slug) { slug }
    @title = attributes.fetch(:title) { title }
    @summary = attributes.fetch(:summary) { summary }
    @body = attributes.fetch(:body) { body }
    @organisation_slug = attributes.fetch(:organisation_slug) { organisation_slug }
    @state = attributes.fetch(:state) { state }
    @originally_published_at = attributes.fetch(:originally_published_at) { originally_published_at }
    @use_originally_published_at_for_public_timestamp = attributes.fetch(:use_originally_published_at_for_public_timestamp) { use_originally_published_at_for_public_timestamp }

    self
  end

  def draft
    @state = "draft"

    self
  end

  def publish
    @state = "published"
    sections.each(&:publish!)

    self
  end

  def draft?
    state == "draft"
  end

  def publication_state
    if withdrawn?
      "withdrawn"
    elsif has_ever_been_published? || published?
      "published"
    else
      "draft"
    end
  end

  def published?
    state == "published"
  end

  def withdraw
    @state = "withdrawn" if state == "published"

    self
  end

  def withdrawn?
    state == "withdrawn"
  end

  def has_ever_been_published?
    @ever_been_published
  end

  def use_originally_published_at_for_public_timestamp?
    !!use_originally_published_at_for_public_timestamp
  end

  def build_section(attributes)
    section = section_builder.call(
      self,
      attributes
    )

    sections << section

    section
  end

  def reorder_sections(section_order)
    unless section_order.sort == sections.map(&:id).sort
      raise(
        ArgumentError,
        "section_order must contain each section_id exactly once",
      )
    end

    sections.sort_by! { |sec| section_order.index(sec.id) }
  end

  def remove_section(section_id)
    found_section = sections.find { |d| d.id == section_id }

    return if found_section.nil?

    removed = sections.delete(found_section)

    return if removed.nil?

    removed_sections << removed
  end

private

  attr_reader :section_builder
end
