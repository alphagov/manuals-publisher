require "spec_helper"
require "spec/exporters/formatters/abstract_indexable_formatter_spec"
require "spec/exporters/formatters/abstract_specialist_document_indexable_formatter_spec"
require "formatters/aaib_report_indexable_formatter"

RSpec.describe UtiacDecisionIndexableFormatter do
  let(:document) {
    double(
      :utiac_decision,
      body: double,
      slug: double,
      summary: double,
      title: double,
      updated_at: double,
      minor_update?: false,

      country: double,
      country_guidance: double,
      decision_reported: double,
      judges: double,
      promulgation_date: double,
    )
  }

  subject(:formatter) { UtiacDecisionIndexableFormatter.new(document) }

  it_should_behave_like "a specialist document indexable formatter"

  it "should have a type of utiac_decision" do
    expect(formatter.type).to eq("utiac_decision")
  end
end
