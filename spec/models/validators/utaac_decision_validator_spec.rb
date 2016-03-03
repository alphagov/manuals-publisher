require "spec_helper"

require "validators/utaac_decision_validator"

RSpec.describe UtaacDecisionValidator do

  let(:entity) {
    double(
      :entity,
      title: double,
      summary: double,
      body: "body",
      tribunal_decision_categories: [double],
      tribunal_decision_decision_date: "2015-11-01",
      tribunal_decision_judges: [double],
      tribunal_decision_sub_categories: [double],
    )
  }
  let(:document_type) { "utaac_decision" }

  subject(:validatable) { UtaacDecisionValidator.new(entity) }

end
