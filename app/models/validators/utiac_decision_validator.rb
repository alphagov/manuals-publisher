require "delegate"
require "validators/date_validator"
require "validators/safe_html_validator"

class UtiacDecisionValidator < SimpleDelegator
  include ActiveModel::Validations

  validates :title, presence: true
  validates :summary, presence: true
  validates :body, presence: true, safe_html: true

  validates :country, presence: true
  validates :country_guidance, presence: true
  validates :decision_reported, presence: true
  validates :judges, presence: true

  validates :promulgation_date, presence: true, date: true
end
