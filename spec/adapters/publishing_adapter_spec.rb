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

  describe "#unpublish_and_redirect_manual_and_sections" do
    let(:redirect) { "/blah/redirect" }
    let(:redirects) do
      [
        { path: "/#{manual.slug}", type: "exact", destination: redirect },
        { path: "/#{manual.slug}/updates", type: "exact", destination: redirect },
      ]
    end

    before do
      allow(publishing_api).to receive(:unpublish)
    end

    it "unpublishes and redirects manual plus sections via Publishing API" do
      manual.sections = [section]

      expect(publishing_api).to receive(:unpublish).with(
        manual_id, type: "redirect", redirects:, discard_drafts: false
      )

      expect(publishing_api).to receive(:unpublish).with(
        section.uuid, type: "redirect", discard_drafts: false, alternative_path: redirect
      )

      PublishingAdapter.unpublish_and_redirect_manual_and_sections(
        manual, redirect:, discard_drafts: false
      )
    end
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

  describe "#publish" do
    let(:removed_section_uuid) { "c146f39b-6512-4e3c-8991-fedda0b02a28" }

    let(:removed_section) do
      Section.new(
        uuid: removed_section_uuid,
        latest_edition: removed_section_edition,
      )
    end

    let(:removed_section_edition) do
      SectionEdition.new(
        slug: "manual-slug/removed-section-slug",
        section_uuid: removed_section_uuid,
        title: "removed-section-title",
        summary: "removed-section-summary",
        body: "removed-section-body",
      )
    end

    before do
      manual.sections = [section]
      manual.removed_sections = [removed_section]

      allow(removed_section).to receive(:withdrawn?).and_return(false)

      allow(publishing_api).to receive(:publish).with(anything, anything)
      allow(publishing_api).to receive(:unpublish).with(anything, anything)
    end

    it "publishes manual to Publishing API" do
      expect(publishing_api).to receive(:publish).with(manual_id, nil)

      PublishingAdapter.publish_manual_and_sections(manual)
    end

    it "publishes all manual's sections to Publishing API" do
      expect(publishing_api).to receive(:publish).with(section_uuid, nil)

      PublishingAdapter.publish_manual_and_sections(manual)
    end

    it "marks all manual's sections as exported" do
      expect(section).to receive(:mark_as_exported!)

      PublishingAdapter.publish_manual_and_sections(manual)
    end

    it "unpublishes all manual's removed sections via Publishing API" do
      expect(publishing_api).to receive(:unpublish).with(
        removed_section_uuid,
        type: "redirect",
        alternative_path: "/manual-slug",
        discard_drafts: true,
      )

      PublishingAdapter.publish_manual_and_sections(manual)
    end

    it "withdraws & marks all manual's removed sections as exported" do
      expect(removed_section).to receive(:withdraw_and_mark_as_exported!)

      PublishingAdapter.publish_manual_and_sections(manual)
    end

    context "when removed section is withdrawn" do
      before do
        allow(removed_section).to receive(:withdrawn?).and_return(true)
      end

      it "does not unpublish all manual's removed sections via Publishing API" do
        expect(publishing_api).not_to receive(:unpublish).with(
          removed_section_uuid,
          anything,
        )

        PublishingAdapter.publish_manual_and_sections(manual)
      end
    end

    context "when action is republish" do
      it "publishes manual to Publishing API with update type set to republish" do
        expect(publishing_api).to receive(:publish).with(manual_id, "republish")

        PublishingAdapter.publish_manual_and_sections(manual, republish: true)
      end

      it "publishes all manual's sections to Publishing API with update type set to republish" do
        expect(publishing_api).to receive(:publish).with(section_uuid, "republish")

        PublishingAdapter.publish_manual_and_sections(manual, republish: true)
      end

      it "does not mark all manual's sections as exported" do
        expect(section).not_to receive(:mark_as_exported!)

        PublishingAdapter.publish_manual_and_sections(manual, republish: true)
      end

      it "unpublishes all manual's removed sections via Publishing API" do
        expect(publishing_api).to receive(:unpublish).with(
          removed_section_uuid,
          anything,
        )

        PublishingAdapter.publish_manual_and_sections(manual, republish: true)
      end

      it "does not mark all manual's removed sections as exported" do
        expect(removed_section).not_to receive(:withdraw_and_mark_as_exported!)

        PublishingAdapter.publish_manual_and_sections(manual, republish: true)
      end

      context "and removed section is withdrawn" do
        before do
          allow(removed_section).to receive(:withdrawn?).and_return(true)
        end

        it "unpublishes all manual's removed sections via Publishing API" do
          expect(publishing_api).to receive(:unpublish).with(
            removed_section_uuid,
            anything,
          )

          PublishingAdapter.publish_manual_and_sections(manual, republish: true)
        end
      end
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
