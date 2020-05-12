require "spec_helper"
require "services"

describe OrganisationsAdapter do
  let(:api) { double(:organisations_api) }

  before do
    allow(Services).to receive(:organisations).and_return(api)
  end

  describe "#find" do
    let(:response) do
      {
        "title" => "organisation-title",
        "web_url" => "organisation-web-url",
        "details" => {
          "abbreviation" => "organisation-abbreviation",
          "content_id" => "organisation-content-id",
        },
      }
    end

    before do
      allow(api).to receive(:organisation).with("slug").and_return(response)
    end

    it "returns an Organisation populated from the Organisations API" do
      organisation = subject.find("slug")

      expect(organisation.title).to eq("organisation-title")
      expect(organisation.abbreviation).to eq("organisation-abbreviation")
      expect(organisation.web_url).to eq("organisation-web-url")
      expect(organisation.content_id).to eq("organisation-content-id")
    end

    it "caches the result for a given slug from the Organisations API" do
      subject.find("slug")
      subject.find("slug")

      expect(api).to have_received(:organisation).with("slug").at_most(:once)
    end
  end
end
