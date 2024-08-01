describe PublishingAdapter do
  let(:publishing_api) { double(:publishing_api) }

  let(:manual_id) { "a55242ed-178f-4716-8bb3-5d4f82d38531" }

  let(:manual) do
    FactoryBot.build(
      :manual,
      id: manual_id,
      slug: "manual-slug",
      organisation_slug: "organisation-slug",
      title: "manual-title",
      summary: "manual-summary",
      body: "manual-body",
    )
  end
  let(:section_uuid) { "64dbf396-b637-40b7-ada4-f19ce460e5e9" }
  let(:section) do
    Section.new(
      uuid: section_uuid,
      latest_edition: section_edition,
    )
  end
  let(:section_edition) do
    SectionEdition.new(
      slug: "manual-slug/section-slug",
      section_uuid:,
      title: "section-title",
      summary: "section-summary",
      body: "section-body",
      change_note: "change-note",
    )
  end

  before do
    allow(Services).to receive(:publishing_api).and_return(publishing_api)
  end

  describe "#unpublish" do
    before do
      manual.sections = [section]

      allow(publishing_api).to receive(:unpublish).with(anything, anything)
    end

    it "unpublishes manual via Publishing API" do
      expect(publishing_api).to receive(:unpublish).with(manual_id, type: "gone")

      PublishingAdapter.unpublish(manual)
    end

    it "unpublishes all manual's sections via Publishing API" do
      expect(publishing_api).to receive(:unpublish).with(section_uuid, type: "gone")

      PublishingAdapter.unpublish(manual)
    end
  end

  describe "#redirect_section" do
    let(:redirect_content_id) { "179cd671-766b-47af-ae4a-5054e9b99b89" }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(redirect_content_id)
    end

    it "redirects section via Publishing API" do
      expect(publishing_api).to receive(:put_content).with(
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
      )

      PublishingAdapter.redirect_section(section, to: "/new-location")
    end

    it "redirects section via Publishing API with attributes which are valid according to redirect schema" do
      expect(publishing_api).to receive(:put_content).with(
        redirect_content_id,
        attributes_valid_according_to_schema("redirect"),
      )

      PublishingAdapter.redirect_section(manual, to: "/new-location")
    end
  end

private

  def attributes_valid_according_to_schema(schema_name)
    be_valid_against_publisher_schema(schema_name)
  end
end
