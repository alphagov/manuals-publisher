class ManualRecord
  include ::Mongoid::Document
  include ::Mongoid::Timestamps

  field :manual_id, type: String
  field :organisation_slug, type: String
  field :slug, type: String

  has_many :editions,
           class_name: "ManualRecord::Edition",
           dependent: :destroy,
           autosave: true

  def self.find_by(attributes)
    where(attributes).first
  end

  def self.all_by_updated_at
    order_by(%i[updated_at desc])
  end

  def new_or_existing_draft_edition
    if latest_edition && latest_edition.state == "draft"
      latest_edition
    else
      build_draft_edition
    end
  end

  def latest_edition
    # NOTE - we cache this because .order_by is a mongoid method that will hit
    # the server each time, also because it's a server command it doesn't look
    # at unsaved instances in the array (such as those created in
    # build_draft_edition below)
    @latest_edition ||= editions.order_by(%i[version_number desc]).first
  end

  def previous_edition
    editions.order_by(%i[version_number desc]).limit(2).last
  end

  def has_ever_been_published?
    editions.any? { |x| x.state == "published" }
  end

  after_save :save_and_clear_latest_edition

private

  def save_and_clear_latest_edition
    if @latest_edition.present?
      @latest_edition.save! if @latest_edition.changed?
      @latest_edition = nil
    end
  end

  def build_draft_edition
    @latest_edition = editions.build(state: "draft", version_number: next_version_number)
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
    field :state, type: String
    field :version_number, type: Integer
    field :section_uuids, type: Array
    field :removed_section_uuids, type: Array
    field :originally_published_at, type: Time
    field :use_originally_published_at_for_public_timestamp, type: Boolean

    index manual_record_id: 1

    # We don't make use of the relationship but Mongoid can't save the
    # timestamps properly without it.
    belongs_to :manual_record

    after_save :touch_manual_record
    before_destroy :touch_manual_record

    def touch_manual_record
      # Apparently touch is a Mongoid 3 thing, so we use the callback code
      # from Mongoid::Timestamps::Updated
      manual_record.set_updated_at if manual_record.able_to_set_updated_at?
    end
  end
end
