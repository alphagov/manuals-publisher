require "delegate"

class SectionValidator < SimpleDelegator
  include ActiveModel::Validations

  validates :summary, presence: true
  validates :title, presence: true
  validates :body, presence: true, safe_html: true
end
