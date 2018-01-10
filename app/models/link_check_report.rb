class LinkCheckReport
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :links

  accepts_nested_attributes_for :links

  field :batch_id, type: Integer
  field :status, type: String
  field :manual_id, type: String
  field :section_id, type: String
  field :completed_at, type: Time

  validates :batch_id, presence: true
  validates :status, presence: true
  validates :links, presence: true
  validates :manual_id, presence: true

  def completed?
    status == "completed"
  end

  def in_progress?
    !completed?
  end

  def broken_links
    links.select { |l| l.status == "broken" }
  end

  def caution_links
    links.select { |l| l.status == "caution" }
  end
end
