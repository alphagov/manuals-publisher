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
  class AmbiguousSlugError < StandardError; end

  def self.find(id, user)
    collection = user.manual_records
    manual_record = collection.find_by(manual_id: id)
    unless manual_record
      raise NotFoundError, "Manual ID not found: #{id}"
    end

    build_manual_for(manual_record)
  end

  def self.find_by_slug!(slug, user)
    collection = user.manual_records
    manual_records = collection.where(slug: slug)
    case manual_records.length
    when 0
      raise NotFoundError, "Manual slug not found: #{slug}"
    when 1
      build_manual_for(manual_records.first)
    else
      raise AmbiguousSlugError, "Multiple manuals found for slug: #{slug}"
    end
  end

  def self.all(user, load_associations: true)
    user.manual_records
      .includes(:editions)
      .all_by_updated_at
      .lazy
      .map do |manual_record|
        edition = manual_record.editions.max_by(&:version_number)

        build_manual_for(
          manual_record,
          edition: edition,
          load_associations: load_associations,
        )
      end
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

  def save!(user)
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

    sections.each(&:save!)
    removed_sections.each(&:save!)

    edition.section_uuids = sections.map(&:uuid)
    edition.removed_section_uuids = removed_sections.map(&:uuid)

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

  def initialize(attributes = {})
    slug_generator = SlugGenerator.new(prefix: "guidance")

    attributes[:slug] ||= slug_generator.call(attributes.fetch(:title, ""))

    @id = attributes.fetch(:id, SecureRandom.uuid)
    @updated_at = attributes.fetch(:updated_at, nil)
    @version_number = attributes.fetch(:version_number, 0)
    @ever_been_published = attributes.fetch(:ever_been_published, false).present?

    assign_attributes(attributes)

    @summary ||= ""
    @body ||= ""
    @state ||= "draft"
    @organisation_slug ||= ""

    if @use_originally_published_at_for_public_timestamp.nil?
      @use_originally_published_at_for_public_timestamp = true
    end

    @sections = attributes.fetch(:sections, [])
    @removed_sections = attributes.fetch(:removed_sections, [])
  end

  def to_param
    id
  end

  def eql?(other)
    id.eql? other.id
  end

  def assign_attributes(attributes)
    @slug = attributes.fetch(:slug, slug)
    @title = attributes.fetch(:title, title)
    @summary = attributes.fetch(:summary, summary)
    @body = attributes.fetch(:body, body)
    @organisation_slug = attributes.fetch(:organisation_slug, organisation_slug)
    @state = attributes.fetch(:state, state)
    @originally_published_at = attributes.fetch(:originally_published_at, originally_published_at)
    @use_originally_published_at_for_public_timestamp = attributes.fetch(:use_originally_published_at_for_public_timestamp, use_originally_published_at_for_public_timestamp)
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
    use_originally_published_at_for_public_timestamp.present?
  end

  def version_type
    if has_ever_been_published?
      if all_sections_are_minor?
        :minor
      else
        :major
      end
    else
      :new
    end
  end

  def all_sections_are_minor?
    sections.select(&:needs_exporting?).all? { |s| s.version_type == :minor }
  end

  def find_section(section_uuid)
    sections.find { |section| section.uuid == section_uuid }
  end

  def build_section(attributes)
    section = Section.new(manual: self, uuid: SecureRandom.uuid)

    defaults = {
      minor_update: false,
      change_note: "New section added.",
    }
    section.assign_attributes(defaults.merge(attributes))

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
    found_section = find_section(section_uuid)

    return if found_section.nil?

    removed = sections.delete(found_section)

    return if removed.nil?

    removed_sections << removed
  end

  class << self
    def build_manual_for(manual_record, edition: nil, load_associations: true, published: false)
      edition ||= manual_record.latest_edition

      base_manual = new(
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
      sections = Array(edition.section_uuids).map do |section_uuid|
        Section.find(manual, section_uuid, published: published)
      end

      removed_sections = Array(edition.removed_section_uuids).map do |section_uuid|
        Section.find(manual, section_uuid)
      rescue KeyError
        raise RemovedSectionIdNotFoundError, "No section found for UUID #{section_uuid}"
      end

      manual.sections = sections
      manual.removed_sections = removed_sections
    end

    def add_publish_tasks_to_manual(manual)
      manual.publish_tasks = ManualPublishTask.for_manual(manual)
    end
  end

  def current_draft_version(manual_record)
    return nil unless manual_record.latest_edition.state == "draft"

    self.class.build_manual_for(manual_record)
  end

  def current_published_version(manual_record)
    if manual_record.latest_edition.state == "published"
      self.class.build_manual_for(manual_record)
    elsif manual_record.latest_edition.state == "draft"
      previous_edition = manual_record.previous_edition

      # This means the previous edition is withdrawn so we shouldn't
      # expose it as it's not actually published (we've got a new
      # draft waiting in the wings for a withdrawn manual)
      return unless previous_edition.state == "published"

      self.class.build_manual_for(manual_record, edition: previous_edition, published: true)
    end
  end

  def publication_logs
    PublicationLog.change_notes_for(slug)
  end

  def destroy!
    sections.each do |section|
      section.all_editions.each(&:destroy)
    end

    manual_record = ManualRecord.find_by(manual_id: id)
    manual_record.destroy!
  end

  def editions
    manual_record = ManualRecord.find_by(manual_id: id)
    manual_record.editions
  end

  def set(attributes = {})
    manual_record = ManualRecord.find_by(manual_id: id)
    manual_record.set(attributes)
  end

  def link_check_report
    @link_check_report ||= LinkCheckReport.where(manual_id: id).last
  end

  class RemovedSectionIdNotFoundError < StandardError; end
end
