require "spec_helper"
require "formatters/aaib_report_indexable_formatter"

RSpec.describe AsylumSupportDecisionIndexableFormatter do
  let(:sub_category) { [double] }
  let(:document) {
    double(
      :asylum_support_decision,
      body: double,
      slug: "/slug",
      summary: double,
      title: double,
      updated_at: double,
      minor_update?: false,
      public_updated_at: double,

      hidden_indexable_content: double,
      tribunal_decision_category: double,
      tribunal_decision_decision_date: double,
      tribunal_decision_judges: [double],
      tribunal_decision_landmark: double,
      tribunal_decision_reference_number: double,
      tribunal_decision_sub_category: sub_category,
    )
  }

  subject(:formatter) { AsylumSupportDecisionIndexableFormatter.new(document) }

  let(:document_type) { formatter.type }
  let(:humanized_facet_value) { double }
  include_context "schema with humanized_facet_value available"

  it_behaves_like "a specialist document indexable formatter"
  it_behaves_like "a tribunal decision indexable formatter"

  it "should have a type of asylum_support_decision" do
    expect(formatter.type).to eq("asylum_support_decision")
  end

  include_examples "tribunal decision hidden_indexable_content"

end
