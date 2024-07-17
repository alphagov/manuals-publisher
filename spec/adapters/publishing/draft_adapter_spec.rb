describe Publishing::DraftAdapter do
  let(:publishing_api) { double(:publishing_api) }
  let(:timestamp) { Time.zone.parse("2017-01-01 00:00:00") }

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

  let(:organisation_content_id) { "afa741e9-c68e-4ade-bc8f-ceb1fced23a6" }
  let(:organisation) do
    Organisation.new(
      title: "organisation-title",
      abbreviation: "organisation-abbreviation",
      content_id: organisation_content_id,
      web_url: "organisation-web-url",
    )
  end

  let(:publication_logs) { [] }

  before do
    allow(Services).to receive(:publishing_api).and_return(publishing_api)
    allow(PublicationLog).to receive(:change_notes_for).with("manual-slug")
                                                       .and_return(publication_logs)
  end

  describe "#save_draft_for_manual_and_sections" do
    before do
      manual.sections = [section]

      allow(manual).to receive(:version_type).and_return(:new)
      allow(section).to receive(:needs_exporting?).and_return(true)

      allow(OrganisationsAdapter).to receive(:find).with("organisation-slug").and_return(organisation)
      allow(publishing_api).to receive(:patch_links).with(anything, anything)
      allow(publishing_api).to receive(:put_content).with(anything, anything)
    end

    it "saves links for manual to Publishing API" do
      expect(publishing_api).to receive(:patch_links).with(
        manual_id,
        links: {
          organisations: [organisation_content_id],
          primary_publishing_organisation: [organisation_content_id],
          sections: [section_uuid],
        },
      )

      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
    end

    it "saves links for manual to Publishing API with attributes which validate against links schema for manual" do
      expect(publishing_api).to receive(:patch_links).with(
        manual_id,
        attributes_valid_according_to_links_schema(
          GdsApiConstants::PublishingApi::MANUAL_SCHEMA_NAME,
        ),
      )

      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
    end

    it "saves content for manual to Publishing API" do
      expect(publishing_api).to receive(:put_content).with(
        manual_id,
        {
          base_path: "/manual-slug",
          schema_name: GdsApiConstants::PublishingApi::MANUAL_SCHEMA_NAME,
          document_type: GdsApiConstants::PublishingApi::MANUAL_DOCUMENT_TYPE,
          title: "manual-title",
          description: "manual-summary",
          update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE,
          bulk_publishing: false,
          publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
          rendering_app: GdsApiConstants::PublishingApi::RENDERING_APP,
          routes: [
            {
              path: "/manual-slug",
              type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
            },
            {
              path: "/manual-slug/#{GdsApiConstants::PublishingApi::UPDATES_PATH_SUFFIX}",
              type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
            },
          ],
          details: {
            body: [
              {
                content_type: "text/govspeak",
                content: "manual-body",
              },
              {
                content_type: "text/html",
                content: "<p>manual-body</p>\n",
              },
            ],
            child_section_groups: [
              {
                title: GdsApiConstants::PublishingApi::CHILD_SECTION_GROUP_TITLE,
                child_sections: [
                  {
                    title: "section-title",
                    description: "section-summary",
                    base_path: "/manual-slug/section-slug",
                  },
                ],
              },
            ],
            change_notes: [],
            organisations: [
              {
                title: "organisation-title",
                abbreviation: "organisation-abbreviation",
                web_url: "organisation-web-url",
              },
            ],
          },
          locale: GdsApiConstants::PublishingApi::EDITION_LOCALE,
        },
      )

      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
    end

    it "saves links for all manual's sections to Publishing API" do
      expect(publishing_api).to receive(:patch_links).with(
        section_uuid,
        links: {
          organisations: [organisation_content_id],
          primary_publishing_organisation: [organisation_content_id],
          manual: [manual_id],
        },
      )

      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
    end

    it "saves links for all manual's sections to Publishing API with attributes which validate against links schema for section" do
      expect(publishing_api).to receive(:patch_links).with(
        section_uuid,
        attributes_valid_according_to_links_schema(
          GdsApiConstants::PublishingApi::SECTION_SCHEMA_NAME,
        ),
      )

      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
    end

    it "saves content for all manual's sections to Publishing API" do
      expect(publishing_api).to receive(:put_content).with(
        section_uuid,
        {
          base_path: "/manual-slug/section-slug",
          schema_name: GdsApiConstants::PublishingApi::SECTION_SCHEMA_NAME,
          document_type: GdsApiConstants::PublishingApi::SECTION_DOCUMENT_TYPE,
          title: "section-title",
          description: "section-summary",
          update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE,
          bulk_publishing: false,
          publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
          rendering_app: GdsApiConstants::PublishingApi::RENDERING_APP,
          change_note: "change-note",
          routes: [
            {
              path: "/manual-slug/section-slug",
              type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
            },
          ],
          details: {
            body: [
              {
                content_type: "text/govspeak",
                content: "section-body",
              },
              {
                content_type: "text/html",
                content: "<p>section-body</p>\n",
              },
            ],
            attachments: [],
            manual: {
              base_path: "/manual-slug",
            },
            organisations: [
              {
                title: "organisation-title",
                abbreviation: "organisation-abbreviation",
                web_url: "organisation-web-url",
              },
            ],
            visually_expanded: false,
          },
          locale: GdsApiConstants::PublishingApi::EDITION_LOCALE,
        },
      )

      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
    end

    context "when section does not need exporting" do
      before do
        allow(section).to receive(:needs_exporting?).and_return(false)
      end

      it "does not save links for section to Publishing API" do
        expect(publishing_api).not_to receive(:patch_links).with(
          section_uuid,
          anything,
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      it "does not save content for section to Publishing API" do
        expect(publishing_api).not_to receive(:put_content).with(
          section_uuid,
          anything,
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      context "and action is republish" do
        it "saves links for section to Publishing API" do
          expect(publishing_api).to receive(:patch_links).with(
            section_uuid,
            anything,
          )

          Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, republish: true)
        end

        it "saves content for section to Publishing API" do
          expect(publishing_api).to receive(:put_content).with(
            section_uuid,
            anything,
          )

          Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, republish: true)
        end
      end
    end

    context "when Manual#originally_published_at is set" do
      before do
        allow(manual).to receive(:originally_published_at).and_return(timestamp)
      end

      it "saves content for manual to Publishing API with timestamps" do
        expect(publishing_api).to receive(:put_content).with(
          manual_id,
          including(
            first_published_at: timestamp,
            public_updated_at: timestamp,
          ),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      it "saves content for section to Publishing API with timestamps" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(
            first_published_at: timestamp,
            public_updated_at: timestamp,
          ),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      context "but Manual#use_originally_published_at_for_public_timestamp? is false" do
        before do
          allow(manual).to receive(:use_originally_published_at_for_public_timestamp?).and_return(false)
        end

        it "saves content for manual to Publishing API without public timestamp" do
          expect(publishing_api).to receive(:put_content).with(
            manual_id,
            excluding(
              public_updated_at: timestamp,
            ),
          )

          Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
        end

        it "saves content for section to Publishing API without public timestamp" do
          expect(publishing_api).to receive(:put_content).with(
            section_uuid,
            excluding(
              public_updated_at: timestamp,
            ),
          )

          Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
        end
      end
    end

    shared_examples_for "republishing overrides update_type and sets bulk_publishing" do
      context "when action is republish" do
        it "saves content for manual to Publishing API with republish update_type" do
          expect(publishing_api).to receive(:put_content).with(
            manual_id,
            including(
              update_type: GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE,
              bulk_publishing: true,
            ),
          )

          Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, republish: true)
        end

        it "saves content for section to Publishing API with republish update_type" do
          expect(publishing_api).to receive(:put_content).with(
            section_uuid,
            including(
              update_type: GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE,
              bulk_publishing: true,
            ),
          )

          Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, republish: true)
        end
      end
    end

    context "when manual & section version_type are new" do
      before do
        allow(manual).to receive(:version_type).and_return(:new)
        allow(section).to receive(:version_type).and_return(:new)
      end

      it "saves content for manual to Publishing API with major update_type" do
        expect(publishing_api).to receive(:put_content).with(
          manual_id,
          including(update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      it "saves content for section to Publishing API with major update_type" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      it_behaves_like "republishing overrides update_type and sets bulk_publishing"
    end

    context "when manual & section version_type are minor" do
      before do
        allow(manual).to receive(:version_type).and_return(:minor)
        allow(section).to receive(:version_type).and_return(:minor)
      end

      it "saves content for manual to Publishing API with minor update_type" do
        expect(publishing_api).to receive(:put_content).with(
          manual_id,
          including(update_type: GdsApiConstants::PublishingApi::MINOR_UPDATE_TYPE),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      it "saves content for section to Publishing API with minor update_type" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(update_type: GdsApiConstants::PublishingApi::MINOR_UPDATE_TYPE),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      it_behaves_like "republishing overrides update_type and sets bulk_publishing"
    end

    context "when manual & section version_type are major" do
      before do
        allow(manual).to receive(:version_type).and_return(:major)
        allow(section).to receive(:version_type).and_return(:major)
      end

      it "saves content for manual to Publishing API with major update_type" do
        expect(publishing_api).to receive(:put_content).with(
          manual_id,
          including(update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      it "saves content for section to Publishing API with major update_type" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      it_behaves_like "republishing overrides update_type and sets bulk_publishing"
    end

    context "when publication logs exist for section" do
      let(:publication_log1) do
        PublicationLog.new(
          title: "section-title",
          slug: "manual-slug/section-slug",
          change_note: "section-change-note",
          published_at: timestamp,
        )
      end

      let(:publication_log2) do
        PublicationLog.new(
          title: "section-title-2",
          slug: "manual-slug/section-slug",
          change_note: "section-change-note",
          published_at: timestamp,
        )
      end

      let(:publication_logs) { [publication_log1, publication_log2] }

      it "saves content for manual to Publishing API including change notes" do
        expect(publishing_api).to receive(:put_content).with(
          manual_id,
          including(
            change_note: "section-title-2 - section-change-note",
            details: including(
              change_notes: [
                {
                  title: "section-title",
                  base_path: "/manual-slug/section-slug",
                  change_note: "section-change-note",
                  published_at: timestamp,
                },
                {
                  title: "section-title-2",
                  base_path: "/manual-slug/section-slug",
                  change_note: "section-change-note",
                  published_at: timestamp,
                },
              ],
            ),
          ),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end
    end

    context "when section has attachments" do
      let(:another_timestamp) { timestamp + 1.day }

      let(:attachment) do
        Attachment.new(
          title: "attachment-title",
          file_url: "attachment-file-url.jpg",
          created_at: timestamp,
          updated_at: another_timestamp,
        )
      end

      let(:attachments) { [attachment] }

      before do
        allow(section).to receive(:attachments).and_return(attachments)
      end

      it "saves content for section to Publishing API including attachments" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(details: including(
            attachments: [
              including(
                title: "attachment-title",
                url: "attachment-file-url.jpg",
                content_type: "application/jpg",
              ),
            ],
          )),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end
    end
  end

private

  def attributes_valid_according_to_links_schema(schema_name)
    be_valid_against_links_schema(schema_name)
  end
end
