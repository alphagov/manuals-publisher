require "delegate"
require "validators/safe_html_validator"

class ManualValidator < SimpleDelegator
  include ActiveModel::Validations

  validates :title, presence: true
  validates :summary, presence: true
  validates :body, safe_html: true
end
