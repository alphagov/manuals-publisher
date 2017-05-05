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
  attr_accessor :publish_tasks

  class NotFoundError < StandardError; end

  def self.find(id, user)
    collection = user.manual_records
    manual_record = collection.find_by(manual_id: id)
    unless manual_record
      raise(NotFoundError.new("Manual ID not found: #{id}"))
    end

    build_manual_for(manual_record)
  end

  def self.all(user, load_associations: true)
    collection = user.manual_records

    collection.all_by_updated_at.lazy.map { |manual_record|
      build_manual_for(manual_record, load_associations: load_associations)
    }
  end

  def self.build(attributes)
    slug_generator = SlugGenerator.new(prefix: "guidance")

    default_attrs = {
      id: SecureRandom.uuid,
      slug: slug_generator.call(attributes.fetch(:title)),
      summary: "",
      body: "",
      state: "draft",
      organisation_slug: "",
      updated_at: "",
      originally_published_at: nil,
      use_originally_published_at_for_public_timestamp: true,
    }

    manual_attrs = default_attrs.merge(attributes)
    manual = Manual.new(manual_attrs)
    manual.sections = manual_attrs.fetch(:sections, [])
    manual.removed_sections = manual_attrs.fetch(:removed_sections, [])
    manual
  end

  def slug_unique?(user)
    user.manual_records.where(
      :slug => slug,
      :manual_id.ne => id,
    ).empty?
  end

  def clashing_sections
    sections
      .group_by(&:slug)
      .select { |_slug, docs| docs.size > 1 }
  end

  def save(user)
    manual_record = user.manual_records.find_or_initialize_by(manual_id: id)
    # TODO: slug must not change after publication
    manual_record.slug = slug
    manual_record.organisation_slug = organisation_slug
    edition = manual_record.new_or_existing_draft_edition
    edition.attributes = {
      title: title,
      summary: summary,
      body: body,
      state: state,
      originally_published_at: originally_published_at,
      use_originally_published_at_for_public_timestamp: use_originally_published_at_for_public_timestamp,
    }

    sections.each(&:save)
    removed_sections.each(&:save)

    edition.section_uuids = sections.map(&:uuid)
    edition.removed_section_ids = removed_sections.map(&:uuid)

    manual_record.save!
  end

  def current_versions
    manual_record = ManualRecord.find_by(manual_id: id)
    raise NotFoundError if manual_record.nil?

    {
      draft: current_draft_version(manual_record),
      published: current_published_version(manual_record),
    }
  end

  def initialize(attributes)
    @id = attributes.fetch(:id)
    @updated_at = attributes.fetch(:updated_at, nil)
    @version_number = attributes.fetch(:version_number, 0)
    @ever_been_published = !!attributes.fetch(:ever_been_published, false)

    update(attributes)

    @sections = []
    @removed_sections = []
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

  def all_sections_are_minor?
    self.
      sections.
      select(&:needs_exporting?).
      all? { |s|
        s.minor_update? && s.has_ever_been_published?
      }
  end

  def build_section(attributes)
    section = Section.build(manual: self, uuid: SecureRandom.uuid, editions: [])

    defaults = {
      minor_update: false,
      change_note: "New section added.",
    }
    section.update(attributes.reverse_merge(defaults))

    sections << section

    section
  end

  def reorder_sections(section_order)
    unless section_order.sort == sections.map(&:uuid).sort
      raise(
        ArgumentError,
        "section_order must contain each section_id exactly once",
      )
    end

    sections.sort_by! { |sec| section_order.index(sec.uuid) }
  end

  def remove_section(section_uuid)
    found_section = sections.find { |d| d.uuid == section_uuid }

    return if found_section.nil?

    removed = sections.delete(found_section)

    return if removed.nil?

    removed_sections << removed
  end

  class << self
    def build_manual_for(manual_record, edition: nil, load_associations: true, published: false)
      edition ||= manual_record.latest_edition

      base_manual = Manual.new(
        id: manual_record.manual_id,
        slug: manual_record.slug,
        title: edition.title,
        summary: edition.summary,
        body: edition.body,
        organisation_slug: manual_record.organisation_slug,
        state: edition.state,
        version_number: edition.version_number,
        updated_at: edition.updated_at,
        ever_been_published: manual_record.has_ever_been_published?,
        originally_published_at: edition.originally_published_at,
        use_originally_published_at_for_public_timestamp: edition.use_originally_published_at_for_public_timestamp,
      )

      if load_associations
        add_sections_to_manual(base_manual, edition, published: published)
        add_publish_tasks_to_manual(base_manual)
      end
      base_manual
    end

    def add_sections_to_manual(manual, edition, published: false)
      sections = Array(edition.section_uuids).map { |section_uuid|
        Section.find(manual, section_uuid, published: published)
      }

      removed_sections = Array(edition.removed_section_ids).map { |section_uuid|
        begin
          Section.find(manual, section_uuid)
        rescue KeyError
          raise RemovedSectionIdNotFoundError, "No section found for UUID #{section_uuid}"
        end
      }

      manual.sections = sections
      manual.removed_sections = removed_sections
    end

    def add_publish_tasks_to_manual(manual)
      manual.publish_tasks = ManualPublishTask.for_manual(manual)
    end
  end

  def current_draft_version(manual_record)
    return nil unless manual_record.latest_edition.state == "draft"

    Manual.build_manual_for(manual_record)
  end

  def current_published_version(manual_record)
    if manual_record.latest_edition.state == "published"
      Manual.build_manual_for(manual_record)
    elsif manual_record.latest_edition.state == "draft"
      previous_edition = manual_record.previous_edition
      if previous_edition.state == "published"
        Manual.build_manual_for(manual_record, edition: previous_edition, published: true)
      else
        # This means the previous edition is withdrawn so we shouldn't
        # expose it as it's not actually published (we've got a new
        # draft waiting in the wings for a withdrawn manual)
        return nil
      end
    else
      # This means the current edition is withdrawn so we shouldn't find
      # the previously published one
      return nil
    end
  end

  class RemovedSectionIdNotFoundError < StandardError; end
end
