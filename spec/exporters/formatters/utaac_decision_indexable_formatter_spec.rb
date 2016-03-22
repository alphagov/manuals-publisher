require "spec_helper"
require "formatters/utaac_decision_indexable_formatter"

RSpec.describe UtaacDecisionIndexableFormatter do
  let(:document) {
    double(
      :utaac_decision,
      body: double,
      slug: "/slug",
      summary: double,
      title: double,
      updated_at: double,
      minor_update?: false,
      public_updated_at: double,

      hidden_indexable_content: double,
      tribunal_decision_categories: [double],
      tribunal_decision_decision_date: double,
      tribunal_decision_judges: [double],
      tribunal_decision_sub_categories: [double],
    )
  }

  subject(:formatter) { UtaacDecisionIndexableFormatter.new(document) }

  let(:document_type) { formatter.type }
  let(:humanized_facet_value) { double }
  include_context "schema with humanized_facet_value available"

  it_behaves_like "a specialist document indexable formatter"

  it "should have a type of utaac_decision" do
    expect(formatter.type).to eq("utaac_decision")
  end

  include_examples "tribunal decision hidden_indexable_content"

end
