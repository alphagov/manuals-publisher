require "rails_helper"

require "validators/utaac_decision_validator"

RSpec.describe UtaacDecisionValidator do

  let(:entity) {
    double(
      :entity,
      title: double,
      summary: double,
      body: "body",
      tribunal_decision_categories: categories,
      tribunal_decision_decision_date: "2015-11-01",
      tribunal_decision_judges: [double],
      tribunal_decision_sub_categories: sub_categories,
    )
  }
  let(:document_type) { "utaac_decision" }

  subject(:validatable) { UtaacDecisionValidator.new(entity) }

  include_examples "tribunal decision sub_categories optional"

end
