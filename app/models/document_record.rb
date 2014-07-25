require "state_machine"

class DocumentRecord
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :document_id, type: String
  field :document_type, type: String
  field :slug, type: String

  embeds_many :editions,
    class_name: "DocumentRecord::Edition",
    cascade_callbacks: true

  def self.find_by(attributes)
    first(conditions: attributes)
  end

  def self.all_by_updated_at(limit, offset = 0)
    order_by([:updated_at, :desc])
      .limit(limit)
      .skip(offset)
  end

  def self.slug_taken_by_another_document?(slug, document_id)
    where(
      :slug => slug,
      :document_id.ne => document_id,
    ).empty?
  end

  def new_or_existing_draft_edition
    if latest_edition && latest_edition.state == "draft"
      latest_edition
    else
      build_draft_edition
    end
  end

  def latest_edition
    editions.order_by([:version_number, :desc]).first
  end

  def save!
    super
    editions.each(&:save!)
  end

private
  def build_draft_edition
    editions.build(state: "draft", version_number: next_version_number)
  end

  def next_version_number
    current_version_number + 1
  end

  def current_version_number
    latest_edition && latest_edition.version_number || 0
  end

  class Edition
    include ::Mongoid::Document
    include ::Mongoid::Timestamps

    field :title, type: String
    field :summary, type: String
    field :body, type: String
    field :slug, type: String
    field :state, type: String, default: "draft"
    field :document_type, type: String
    field :extra_fields, type: Hash, default: {}
    field :change_note, type: String
    field :minor_update, type: Boolean
    field :version_number, type: Integer

    # We don't make use of the relationship but Mongiod can't save the
    # timestamps properly without it.
    embedded_in "DocumentRecord"

    embeds_many :attachments #, cascade_callbacks: true

    def publish
      self.state = "published" if draft?
    end

    def archive
      self.state = "archived" if published?
    end

    def draft?
      state == "draft"
    end

    def published?
      state == "published"
    end

    def archived?
      state == "archived"
    end

    def build_attachment(attributes)
      attachments.build(attributes.merge(
        filename: attributes.fetch(:file).original_filename
      ))
    end

    def save!
      attachments.each do |attachment|
        time = Time.now
        attachment.created_at ||= time
        attachment.updated_at = time
        attachment.save!
      end
      super
    end

  end
end
