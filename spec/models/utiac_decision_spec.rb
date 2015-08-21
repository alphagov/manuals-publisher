require "fast_spec_helper"
require "aaib_report"

RSpec.describe UtiacDecision do

  it "is a DocumentMetadataDecorator" do
    doc = double(:document)
    expect(UtiacDecision.new(doc)).to be_a(DocumentMetadataDecorator)
  end

end
