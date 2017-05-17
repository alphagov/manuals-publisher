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

  def self.edition_attributes
    [
      :title,
      :slug,
      :summary,
      :body,
      :updated_at,
      :version_number,
      :change_note,
      :minor_update,
      :public_updated_at
    ]
  end

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
      Section.new(manual: manual, uuid: section_uuid, editions: editions)
    end
  end

  def_delegators :latest_edition, *edition_attributes

  attr_reader :uuid, :editions, :latest_edition

  def initialize(manual:, uuid:, editions:)
    @slug_generator = SlugGenerator.new(prefix: manual.slug)
    @uuid = uuid
    @editions = editions
    @editions.push(create_first_edition) if @editions.empty?
    @latest_edition = @editions.last
  end

  def save
    # It is actually only necessary to save the latest edition, however, I
    # think it's safer to save latest two as both are exposed to the and have
    # potential to change. This extra write may save a potential future
    # headache.
    editions.last(2).each(&:save!)
  end

  def minor_update?
    !!minor_update
  end

  def to_param
    uuid
  end

  def update(params)
    params = params
      .select { |k, _| allowed_update_params.include?(k.to_s) }
      .symbolize_keys

    if never_published? && params.fetch(:title, false)
      params = params.merge(
        slug: slug_generator.call(params.fetch(:title))
      )
    end

    if draft?
      latest_edition.assign_attributes(params)
    else
      @latest_edition = new_draft(params)
      editions.push(@latest_edition)
    end

    nil
  end

  def published?
    editions.any?(&:published?)
  end

  def has_ever_been_published?
    return false if @editions.size == 1 && needs_exporting?
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
      published_edition.archive if published_edition

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

  def published_edition
    if most_recent_non_draft && most_recent_non_draft.published?
      most_recent_non_draft
    end
  end

  def needs_exporting?
    latest_edition.exported_at.nil?
  end

  def mark_as_exported!(exported_at = Time.zone.now)
    edition = latest_edition
    edition.exported_at = exported_at
    edition.save
  end

  def persisted?
    editions.any?(&:persisted?)
  end

  def eql?(other)
    uuid.eql?(other.uuid)
  end

  def never_published?
    !published?
  end

  def change_note_required?
    !(never_published? || minor_update?)
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

protected

  attr_reader :slug_generator

  def new_edition_defaults
    {
      state: "draft",
      version_number: 1,
      section_uuid: uuid,
    }
  end

  def create_first_edition
    SectionEdition.new(new_edition_defaults)
  end

  def new_draft(params = {})
    new_edition_attributes = previous_edition_attributes
      .merge(new_edition_defaults)
      .merge(params)
      .merge(
        version_number: current_version_number + 1,
        slug: slug,
        attachments: attachments,
      )

    SectionEdition.new(new_edition_attributes)
  end

  def current_version_number
    latest_edition.version_number
  end

  def most_recent_non_draft
    editions.reject(&:draft?).last
  end

  def previous_edition_attributes
    latest_edition.attributes
      .slice(:section_uuid, :version_number, :title, :slug, :summary, :body, :state, :change_note, :minor_update, :public_updated_at)
      .symbolize_keys
  end

  def allowed_update_params
    self.class.edition_attributes
      .-(unupdatable_attributes)
      .map(&:to_s)
  end

  def unupdatable_attributes
    [
      :updated_at,
      :slug,
      :version_number,
    ]
  end

  def change_note_ok
    if change_note_required? && !change_note.present?
      errors.add(:change_note, "You must provide a change note or indicate minor update")
    end
  end
end
