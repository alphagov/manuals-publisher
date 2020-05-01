require "spec_helper"

RSpec.describe LinkCheckReport::LinkExtractorService do
  let(:body) do
    %{
## Heading

[link](http://www.example.com)

[link_two](http://www.gov.com)

[not_a_link](#somepage)

[mailto:](mailto:someone@www.example.com)

[absolute_path](/cais-trwydded-yrru-dros-dro)
    }
  end

  let(:website_root) { Plek.new.website_root }

  subject { described_class.new(body: body).call }

  it "should contain three full urls" do
    expected_result = %W[http://www.example.com http://www.gov.com #{website_root}/cais-trwydded-yrru-dros-dro]

    expect(subject).to match(expected_result)
  end

  it "should not contain a mailto" do
    expect(subject).not_to include("mailto:someone@www.example.com")
  end

  it "should not an anchor" do
    expect(subject).not_to include("#somepage")
  end
end
