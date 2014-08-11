class PublicationLog
  include Mongoid::Document
  include Mongoid::Timestamps

  field :slug, type: String
  field :title, type: String
  field :change_note, type: String
  field :document_state, type: String
  field :version_number, type: Integer

  validates :slug, presence: true
  validates :version_number, presence: true

  alias_attribute :published_at, :created_at

  scope :with_slug_prefix, ->(slug) { where(slug: /^#{slug}.*/) }
  scope :where_publishing_completed, where(document_state: "published")
end
