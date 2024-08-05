describe Publishing::DraftAdapter do
  let(:timestamp) { Time.zone.parse("2017-01-01 00:00:00") }

  let(:manual_id) { "a55242ed-178f-4716-8bb3-5d4f82d38531" }
  let(:manual) do
    FactoryBot.build(
      :manual,
      id: manual_id,
      organisation_slug: "org-slug",
      body: "manual-body",
    )
  end

  let(:section_one_uuid) { "11111111-b637-40b7-ada4-f19ce460e5e9" }
  let(:section_one) { FactoryBot.build(:section, uuid: section_one_uuid) }
  let(:section_two_uuid) { "22222222-b637-40b7-ada4-f19ce460e5e9" }
  let(:section_two) { FactoryBot.build(:section, uuid: section_two_uuid) }

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
    allow(PublicationLog).to receive(:change_notes_for).with(manual.slug)
                                                       .and_return(publication_logs)
    allow(OrganisationsAdapter).to receive(:find).with(manual.organisation_slug).and_return(organisation)
    allow(Services.publishing_api).to receive(:patch_links).with(anything, anything)
    allow(Services.publishing_api).to receive(:put_content).with(anything, anything)

    manual.sections = [section_one, section_two]

    allow(manual).to receive(:version_type).and_return(:new)
    allow(section_one).to receive(:needs_exporting?).and_return(true)
    allow(section_two).to receive(:needs_exporting?).and_return(true)
  end

  describe "#save_draft_for_manual_and_sections" do
    it "does not patch links for manual to Publishing API when not include linkes" do
      expect(Services.publishing_api).to_not receive(:patch_links)

      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, include_links: false)
    end

    it "patch links for manual to Publishing API" do
      expect(Services.publishing_api).to receive(:patch_links).with(
        manual_id,
        links: {
          organisations: [organisation_content_id],
          primary_publishing_organisation: [organisation_content_id],
          sections: [section_one_uuid, section_two_uuid],
        },
      )

      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
    end

    it "patch links for manual to Publishing API with attributes which validate against links schema for manual" do
      expect(Services.publishing_api).to receive(:patch_links).with(
        manual_id,
        attributes_valid_according_to_links_schema(
          GdsApiConstants::PublishingApi::MANUAL_SCHEMA_NAME,
        ),
      )

      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
    end

    it "saves content for manual to Publishing API" do
      expect(Publishing::DraftAdapter).to receive(:save_draft_for_section).twice
      expect(Services.publishing_api).to receive(:put_content).with(
        manual_id,
        {
          base_path: "/#{manual.slug}",
          schema_name: GdsApiConstants::PublishingApi::MANUAL_SCHEMA_NAME,
          document_type: GdsApiConstants::PublishingApi::MANUAL_DOCUMENT_TYPE,
          title: manual.title,
          description: manual.summary,
          update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE,
          bulk_publishing: false,
          publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
          rendering_app: GdsApiConstants::PublishingApi::RENDERING_APP,
          routes: [
            {
              path: "/#{manual.slug}",
              type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
            },
            {
              path: "/#{manual.slug}/#{GdsApiConstants::PublishingApi::UPDATES_PATH_SUFFIX}",
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
                    title: section_one.title,
                    description: section_one.summary,
                    base_path: "/#{section_one.slug}",
                  },
                  {
                    title: section_two.title,
                    description: section_two.summary,
                    base_path: "/#{section_two.slug}",
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

    it "saves all sections for manual to Publishing API" do
      expect(Publishing::DraftAdapter).to receive(:save_draft_for_section).with(section_one, manual, include_links: true, republish: false)
      expect(Publishing::DraftAdapter).to receive(:save_draft_for_section).with(section_two, manual, include_links: true, republish: false)
      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
    end

    it "does not saves sections for manual to Publishing API when not include sections" do
      expect(Publishing::DraftAdapter).to receive(:save_draft_for_section).never
      Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, include_sections: false)
    end

    context "when publication logs exist" do
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
        expect(Services.publishing_api).to receive(:put_content).with(
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

    context "when Manual#originally_published_at is set" do
      before do
        allow(manual).to receive(:originally_published_at).and_return(timestamp)
      end

      it "saves content for manual to Publishing API with timestamps" do
        expect(Services.publishing_api).to receive(:put_content).with(
          manual_id,
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
          expect(Services.publishing_api).to receive(:put_content).with(
            manual_id,
            excluding(
              public_updated_at: timestamp,
            ),
          )

          Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
        end
      end
    end

    context "when manual version_type are new" do
      before do
        allow(manual).to receive(:version_type).and_return(:new)
      end

      it "saves content for manual to Publishing API with major update_type" do
        expect(Services.publishing_api).to receive(:put_content).with(
          manual_id,
          including(update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      it "saves content for manual to Publishing API with republish update_type when republishing is true" do
        expect(Services.publishing_api).to receive(:put_content).with(
          manual_id,
          including(
            update_type: GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE,
            bulk_publishing: true,
          ),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, republish: true)
      end
    end

    context "when manual version_type are minor" do
      before do
        allow(manual).to receive(:version_type).and_return(:minor)
      end

      it "saves content for manual to Publishing API with minor update_type" do
        expect(Services.publishing_api).to receive(:put_content).with(
          manual_id,
          including(update_type: GdsApiConstants::PublishingApi::MINOR_UPDATE_TYPE),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      it "saves content for manual to Publishing API with republish update_type when republishing is true" do
        expect(Services.publishing_api).to receive(:put_content).with(
          manual_id,
          including(
            update_type: GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE,
            bulk_publishing: true,
          ),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, republish: true)
      end
    end

    context "when manual version_type are major" do
      before do
        allow(manual).to receive(:version_type).and_return(:major)
      end

      it "saves content for manual to Publishing API with major update_type" do
        expect(Services.publishing_api).to receive(:put_content).with(
          manual_id,
          including(update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual)
      end

      it "saves content for manual to Publishing API with republish update_type when republishing is true" do
        expect(Services.publishing_api).to receive(:put_content).with(
          manual_id,
          including(
            update_type: GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE,
            bulk_publishing: true,
          ),
        )

        Publishing::DraftAdapter.save_draft_for_manual_and_sections(manual, republish: true)
      end
    end
  end

  describe "#save_draft_for_section" do
    it "does not patch links for section to Publishing API when not include linkes" do
      expect(Services.publishing_api).to_not receive(:patch_links)

      Publishing::DraftAdapter.save_draft_for_section(section_one, manual, include_links: false)
    end

    it "patch links for section to Publishing API" do
      expect(Services.publishing_api).to receive(:patch_links).with(
        section_one_uuid,
        links: {
          organisations: [organisation_content_id],
          primary_publishing_organisation: [organisation_content_id],
          manual: [manual_id],
        },
      )

      Publishing::DraftAdapter.save_draft_for_section(section_one, manual)
    end

    it "patch links for section to Publishing API with attributes which validate against links schema for section" do
      expect(Services.publishing_api).to receive(:patch_links).with(
        section_one_uuid,
        attributes_valid_according_to_links_schema(
          GdsApiConstants::PublishingApi::SECTION_SCHEMA_NAME,
        ),
      )

      Publishing::DraftAdapter.save_draft_for_section(section_one, manual)
    end

    it "saves content for section to Publishing API" do
      expect(Services.publishing_api).to receive(:put_content).with(
        section_one_uuid,
        {
          base_path: "/#{section_one.slug}",
          schema_name: GdsApiConstants::PublishingApi::SECTION_SCHEMA_NAME,
          document_type: GdsApiConstants::PublishingApi::SECTION_DOCUMENT_TYPE,
          title: section_one.title,
          description: section_one.summary,
          update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE,
          bulk_publishing: false,
          publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
          rendering_app: GdsApiConstants::PublishingApi::RENDERING_APP,
          change_note: "New section added",
          routes: [
            {
              path: "/#{section_one.slug}",
              type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
            },
          ],
          details: {
            body: [
              {
                content_type: "text/govspeak",
                content: "My body",
              },
              {
                content_type: "text/html",
                content: "<p>My body</p>\n",
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

      Publishing::DraftAdapter.save_draft_for_section(section_one, manual)
    end

    context "when section does not need exporting" do
      before do
        allow(section_one).to receive(:needs_exporting?).and_return(false)
      end

      it "does not save links for section to Publishing API" do
        expect(Services.publishing_api).not_to receive(:patch_links)
        Publishing::DraftAdapter.save_draft_for_section(section_one, manual)
      end

      it "does not save content for section to Publishing API" do
        expect(Services.publishing_api).not_to receive(:put_content)
        Publishing::DraftAdapter.save_draft_for_section(section_one, manual)
      end

      context "and action is republish" do
        it "saves links for section to Publishing API" do
          expect(Services.publishing_api).to receive(:patch_links).with(
            section_one_uuid,
            anything,
          )

          Publishing::DraftAdapter.save_draft_for_section(section_one, manual, republish: true)
        end

        it "saves content for section to Publishing API" do
          expect(Services.publishing_api).to receive(:put_content).with(
            section_one_uuid,
            anything,
          )

          Publishing::DraftAdapter.save_draft_for_section(section_one, manual, republish: true)
        end
      end
    end

    context "when Manual#originally_published_at is set" do
      before do
        allow(manual).to receive(:originally_published_at).and_return(timestamp)
      end

      it "saves content for section to Publishing API with timestamps" do
        expect(Services.publishing_api).to receive(:put_content).with(
          section_one_uuid,
          including(
            first_published_at: timestamp,
            public_updated_at: timestamp,
          ),
        )

        Publishing::DraftAdapter.save_draft_for_section(section_one, manual)
      end

      context "but Manual#use_originally_published_at_for_public_timestamp? is false" do
        before do
          allow(manual).to receive(:use_originally_published_at_for_public_timestamp?).and_return(false)
        end

        it "saves content for section to Publishing API without public timestamp" do
          expect(Services.publishing_api).to receive(:put_content).with(
            section_one_uuid,
            excluding(
              public_updated_at: timestamp,
            ),
          )

          Publishing::DraftAdapter.save_draft_for_section(section_one, manual)
        end
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
        allow(section_one).to receive(:attachments).and_return(attachments)
      end

      it "saves content for section to Publishing API including attachments" do
        expect(Services.publishing_api).to receive(:put_content).with(
          section_one_uuid,
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

        Publishing::DraftAdapter.save_draft_for_section(section_one, manual)
      end
    end

    context "when section version_type are new" do
      before do
        allow(section_one).to receive(:version_type).and_return(:new)
      end

      it "saves content for section to Publishing API with major update_type" do
        expect(Services.publishing_api).to receive(:put_content).with(
          section_one_uuid,
          including(update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE),
        )
        Publishing::DraftAdapter.save_draft_for_section(section_one, manual)
      end

      it "saves content for section to Publishing API with republish update_type when republishing is true" do
        expect(Services.publishing_api).to receive(:put_content).with(
          section_one_uuid,
          including(
            update_type: GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE,
            bulk_publishing: true,
          ),
        )

        Publishing::DraftAdapter.save_draft_for_section(section_one, manual, republish: true)
      end
    end

    context "when section version_type are minor" do
      before do
        allow(section_one).to receive(:version_type).and_return(:minor)
      end

      it "saves content for section to Publishing API with minor update_type" do
        expect(Services.publishing_api).to receive(:put_content).with(
          section_one_uuid,
          including(update_type: GdsApiConstants::PublishingApi::MINOR_UPDATE_TYPE),
        )

        Publishing::DraftAdapter.save_draft_for_section(section_one, manual)
      end

      it "saves content for section to Publishing API with republish update_type when republishing is true" do
        expect(Services.publishing_api).to receive(:put_content).with(
          section_one_uuid,
          including(
            update_type: GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE,
            bulk_publishing: true,
          ),
        )

        Publishing::DraftAdapter.save_draft_for_section(section_one, manual, republish: true)
      end
    end

    context "when section version_type are major" do
      before do
        allow(section_one).to receive(:version_type).and_return(:major)
      end

      it "saves content for section to Publishing API with major update_type" do
        expect(Services.publishing_api).to receive(:put_content).with(
          section_one_uuid,
          including(update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE),
        )

        Publishing::DraftAdapter.save_draft_for_section(section_one, manual)
      end

      it "saves content for section to Publishing API with republish update_type when republishing is true" do
        expect(Services.publishing_api).to receive(:put_content).with(
          section_one_uuid,
          including(
            update_type: GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE,
            bulk_publishing: true,
          ),
        )

        Publishing::DraftAdapter.save_draft_for_section(section_one, manual, republish: true)
      end
    end
  end

  describe "#discard_draft_for_manual_and_sections" do
    it "discards draft manual and its sections via Publishing API" do
      expect(Services.publishing_api).to receive(:discard_draft).with(manual_id)
      expect(Services.publishing_api).to receive(:discard_draft).with(section_one_uuid)
      expect(Services.publishing_api).to receive(:discard_draft).with(section_two_uuid)
      Publishing::DraftAdapter.discard_draft_for_manual_and_sections(manual)
    end
  end

  describe "#discard_draft_for_section" do
    it "discards draft section via Publishing API" do
      expect(Services.publishing_api).to receive(:discard_draft).with(section_one_uuid)
      Publishing::DraftAdapter.discard_draft_for_section(section_one)
    end
  end

private

  def attributes_valid_according_to_links_schema(schema_name)
    be_valid_against_links_schema(schema_name)
  end
end
