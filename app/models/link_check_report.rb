class LinkCheckReport
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :links

  accepts_nested_attributes_for :links

  field :batch_id, type: Integer
  field :status, type: String
  field :manual_id, type: String
  field :section_id, type: String
  field :completed_at, type: DateTime

  validates :batch_id, presence: true
  validates :status, presence: true
  validates :links, presence: true
  validates :manual_id, presence: true
end
