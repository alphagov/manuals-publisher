require "forwardable"
require "active_model/conversion"
require "active_model/naming"
require "slug_generator"

class Section
  include ActiveModel::Validations

  extend Forwardable

  validates :summary, presence: true
  validates :title, presence: true
  validates :body, presence: true, safe_html: true
  validate :change_note_ok

  def self.find(manual, section_uuid, published: false)
    editions = SectionEdition
      .all_for_section(section_uuid)
      .order_by([:version_number, :desc])
      .to_a
      .drop_while { |e| published && !e.published? }
      .take(2)
      .reverse

    if editions.empty?
      raise KeyError.new("key not found #{section_uuid}")
    else
      Section.new(manual: manual, uuid: section_uuid, previous_edition: editions.first, latest_edition: editions.last)
    end
  end

  def_delegators :latest_edition, :title, :slug, :summary, :body, :updated_at, :version_number, :change_note, :minor_update, :exported_at

  attr_reader :uuid

  def initialize(manual:, uuid:, previous_edition: nil, latest_edition: nil)
    @slug_generator = SlugGenerator.new(prefix: manual.slug)
    @uuid = uuid

    @previous_edition = previous_edition
    @latest_edition = latest_edition

    if @previous_edition == @latest_edition
      @previous_edition = nil
    end

    if @latest_edition.nil?
      @latest_edition = SectionEdition.new(state: "draft", version_number: 1, section_uuid: uuid)
    end
  end

  def update_slug!(full_new_section_slug)
    latest_edition.update_attribute(:slug, full_new_section_slug)
  end

  def save
    # It is actually only necessary to save the latest edition, however, I
    # think it's safer to save latest two as both are exposed to the and have
    # potential to change. This extra write may save a potential future
    # headache.
    previous_edition && previous_edition.save!
    latest_edition.save!
  end

  def minor_update?
    !!minor_update
  end

  def to_param
    uuid
  end

  def update(attributes)
    if !published? && attributes.fetch(:title, false)
      attributes = attributes.merge(
        slug: slug_generator.call(attributes.fetch(:title))
      )
    end

    if draft?
      latest_edition.assign_attributes(attributes)
    else
      previous_edition_attributes = latest_edition.attributes
        .slice(:section_uuid, :version_number, :title, :slug, :summary, :body, :state, :change_note, :minor_update)
        .symbolize_keys

      attributes = previous_edition_attributes
        .merge(attributes)
        .merge(
          state: 'draft',
          version_number: latest_edition.version_number + 1,
          slug: slug,
          attachments: attachments,
        )
      @previous_edition = latest_edition
      @latest_edition = SectionEdition.new(attributes)
    end

    nil
  end

  def published?
    latest_edition.published? ||
      (previous_edition && previous_edition.published?)
  end

  def has_ever_been_published?
    return false if previous_edition.nil? && needs_exporting?
    published?
  end

  def draft?
    latest_edition.draft?
  end

  def add_attachment(attributes)
    latest_edition.build_attachment(attributes)
  end

  def attachments
    latest_edition.attachments.to_a
  end

  def publish!
    unless latest_edition.published?
      if previous_edition && previous_edition.published?
        previous_edition.archive
      end

      latest_edition.publish
    end
  end

  def withdraw_and_mark_as_exported!(exported_at = Time.zone.now)
    edition = latest_edition
    edition.exported_at = exported_at
    edition.archive unless withdrawn?
  end

  def withdrawn?
    latest_edition.archived?
  end

  def find_attachment_by_id(attachment_id)
    attachments.find { |a| a.id.to_s == attachment_id }
  end

  def needs_exporting?
    latest_edition.exported_at.nil?
  end

  def reload
    latest_edition.reload
  end

  def mark_as_exported!(exported_at = Time.zone.now)
    edition = latest_edition
    edition.exported_at = exported_at
    edition.save
  end

  def persisted?
    latest_edition.persisted? ||
      (previous_edition && previous_edition.persisted?)
  end

  def eql?(other)
    uuid.eql?(other.uuid)
  end

  def change_note_required?
    published? && !minor_update?
  end

  def version_type
    if has_ever_been_published?
      if minor_update?
        :minor
      else
        :major
      end
    else
      :new
    end
  end

  def all_editions
    SectionEdition.all_for_section(uuid)
  end

private

  attr_reader :slug_generator, :latest_edition, :previous_edition

  def change_note_ok
    if change_note_required? && !change_note.present?
      errors.add(:change_note, "You must provide a change note or indicate minor update")
    end
  end
end
