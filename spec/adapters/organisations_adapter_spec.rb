describe OrganisationsAdapter do
  let(:api) { double(:organisations_api) }
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
    allow(Services).to receive(:organisations).and_return(api)
    allow(api).to receive(:organisation).with("slug").and_return(response)
  end

  describe "#find" do
    it "returns an Organisation populated from the Organisations API" do
      organisation = OrganisationsAdapter.find("slug")

      expect(organisation.title).to eq("organisation-title")
      expect(organisation.abbreviation).to eq("organisation-abbreviation")
      expect(organisation.web_url).to eq("organisation-web-url")
      expect(organisation.content_id).to eq("organisation-content-id")
    end

    it "caches the result for a given slug from the Organisations API" do
      OrganisationsAdapter.find("slug")
      OrganisationsAdapter.find("slug")

      expect(api).to have_received(:organisation).with("slug").at_most(:once)
    end
  end
end
