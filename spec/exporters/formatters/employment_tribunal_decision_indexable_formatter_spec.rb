require "spec_helper"
require "formatters/aaib_report_indexable_formatter"

RSpec.describe EmploymentTribunalDecisionIndexableFormatter do
  let(:document) {
    double(
      :employment_tribunal_decision,
      body: double,
      slug: "/slug",
      summary: double,
      title: double,
      updated_at: double,
      minor_update?: false,
      public_updated_at: double,

      hidden_indexable_content: double,
      tribunal_decision_categories: [double],
      tribunal_decision_country: double,
      tribunal_decision_decision_date: double,
    )
  }

  subject(:formatter) { EmploymentTribunalDecisionIndexableFormatter.new(document) }

  let(:document_type) { formatter.type }
  let(:humanized_facet_value) { double }
  include_context "schema with humanized_facet_value available"

  it_should_behave_like "a specialist document indexable formatter"

  it "should have a type of employment_tribunal_decision" do
    expect(formatter.type).to eq("employment_tribunal_decision")
  end

  include_examples "tribunal decision hidden_indexable_content"

end
