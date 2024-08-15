describe Publishing::RedirectAdapter do
  let(:section_uuid) { "11111111-b637-40b7-ada4-f19ce460e5e9" }
  let(:section) { FactoryBot.build(:section, uuid: section_uuid, state: "published", slug: "manual-slug/section-slug") }
  let(:redirect_content_id) { "179cd671-766b-47af-ae4a-5054e9b99b89" }

  before do
    allow(SecureRandom).to receive(:uuid).and_return(redirect_content_id)
  end

  describe "#redirect_section" do
    it "redirects section via Publishing API" do
      expect(Services.publishing_api).to receive(:put_content).with(
        redirect_content_id,
        base_path: "/manual-slug/section-slug",
        schema_name: "redirect",
        document_type: "redirect",
        publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
        redirects: [
          {
            path: "/manual-slug/section-slug",
            type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
            destination: "/new-location",
          },
        ],
        update_type: "major",
      )
      expect(Services.publishing_api).to receive(:publish).with(redirect_content_id)
      Publishing::RedirectAdapter.redirect_section(section, to: "/new-location")
    end

    it "redirects section via Publishing API with attributes which are valid according to redirect schema" do
      expect(Services.publishing_api).to receive(:put_content).with(
        redirect_content_id,
        be_valid_against_publisher_schema("redirect"),
      )
      expect(Services.publishing_api).to receive(:publish).with(redirect_content_id)
      Publishing::RedirectAdapter.redirect_section(section, to: "/new-location")
    end

    it "redirects manuals too" do
      manual = FactoryBot.build(:manual, state: "published", slug: "manual-slug")
      expect(Services.publishing_api).to receive(:put_content).with(
        redirect_content_id,
        base_path: "/manual-slug",
        schema_name: "redirect",
        document_type: "redirect",
        publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
        redirects: [
          {
            path: "/manual-slug",
            type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
            destination: "/new-location",
          },
        ],
        update_type: "major",
      )
      expect(Services.publishing_api).to receive(:publish).with(redirect_content_id)
      Publishing::RedirectAdapter.redirect_section(manual, to: "/new-location")
    end
  end
end
