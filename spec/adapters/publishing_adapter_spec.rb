require "spec_helper"
require "services"
require "gds_api_constants"

describe PublishingAdapter do
  let(:publishing_api_schema_name_for_manual) do
    GdsApiConstants::PublishingApi::MANUAL_SCHEMA_NAME
  end

  let(:publishing_api_document_type_for_manual) do
    GdsApiConstants::PublishingApi::MANUAL_DOCUMENT_TYPE
  end

  let(:publishing_api_schema_name_for_section) do
    GdsApiConstants::PublishingApi::SECTION_SCHEMA_NAME
  end

  let(:publishing_api_document_type_for_section) do
    GdsApiConstants::PublishingApi::SECTION_DOCUMENT_TYPE
  end

  let(:timestamp) { Time.zone.parse("2017-01-01 00:00:00") }

  let(:publishing_api) { double(:publishing_api) }
  let(:organisations) { double(:organisations_adapter) }

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
      manual: manual,
      uuid: section_uuid,
      latest_edition: section_edition,
    )
  end

  let(:section_edition) do
    SectionEdition.new(
      slug: "manual-slug/section-slug",
      section_uuid: section_uuid,
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
    allow(Adapters).to receive(:organisations).and_return(organisations)

    allow(PublicationLog).to receive(:change_notes_for).with("manual-slug")
      .and_return(publication_logs)
  end

  describe "#save_draft" do
    before do
      manual.sections = [section]

      allow(manual).to receive(:version_type).and_return(:new)
      allow(section).to receive(:needs_exporting?).and_return(true)

      allow(organisations).to receive(:find).with("organisation-slug").and_return(organisation)
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

      subject.save_draft(manual)
    end

    it "saves links for manual to Publishing API with attributes which validate against links schema for manual" do
      expect(publishing_api).to receive(:patch_links).with(
        manual_id,
        attributes_valid_according_to_links_schema(
          publishing_api_schema_name_for_manual,
        ),
      )

      subject.save_draft(manual)
    end

    it "saves content for manual to Publishing API" do
      expect(publishing_api).to receive(:put_content).with(
        manual_id,
        base_path: "/manual-slug",
        schema_name: publishing_api_schema_name_for_manual,
        document_type: publishing_api_document_type_for_manual,
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
      )

      subject.save_draft(manual)
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

      subject.save_draft(manual)
    end

    it "saves links for all manual's sections to Publishing API with attributes which validate against links schema for section" do
      expect(publishing_api).to receive(:patch_links).with(
        section_uuid,
        attributes_valid_according_to_links_schema(
          publishing_api_schema_name_for_section,
        ),
      )

      subject.save_draft(manual)
    end

    it "saves content for all manual's sections to Publishing API" do
      expect(publishing_api).to receive(:put_content).with(
        section_uuid,
        base_path: "/manual-slug/section-slug",
        schema_name: publishing_api_schema_name_for_section,
        document_type: publishing_api_document_type_for_section,
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
      )

      subject.save_draft(manual)
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

        subject.save_draft(manual)
      end

      it "does not save content for section to Publishing API" do
        expect(publishing_api).not_to receive(:put_content).with(
          section_uuid,
          anything,
        )

        subject.save_draft(manual)
      end

      context "and action is republish" do
        it "saves links for section to Publishing API" do
          expect(publishing_api).to receive(:patch_links).with(
            section_uuid,
            anything,
          )

          subject.save_draft(manual, republish: true)
        end

        it "saves content for section to Publishing API" do
          expect(publishing_api).to receive(:put_content).with(
            section_uuid,
            anything,
          )

          subject.save_draft(manual, republish: true)
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

        subject.save_draft(manual)
      end

      it "saves content for section to Publishing API with timestamps" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(
            first_published_at: timestamp,
            public_updated_at: timestamp,
          ),
        )

        subject.save_draft(manual)
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

          subject.save_draft(manual)
        end

        it "saves content for section to Publishing API without public timestamp" do
          expect(publishing_api).to receive(:put_content).with(
            section_uuid,
            excluding(
              public_updated_at: timestamp,
            ),
          )

          subject.save_draft(manual)
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

          subject.save_draft(manual, republish: true)
        end

        it "saves content for section to Publishing API with republish update_type" do
          expect(publishing_api).to receive(:put_content).with(
            section_uuid,
            including(
              update_type: GdsApiConstants::PublishingApi::REPUBLISH_UPDATE_TYPE,
              bulk_publishing: true,
            ),
          )

          subject.save_draft(manual, republish: true)
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

        subject.save_draft(manual)
      end

      it "saves content for section to Publishing API with major update_type" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE),
        )

        subject.save_draft(manual)
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

        subject.save_draft(manual)
      end

      it "saves content for section to Publishing API with minor update_type" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(update_type: GdsApiConstants::PublishingApi::MINOR_UPDATE_TYPE),
        )

        subject.save_draft(manual)
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

        subject.save_draft(manual)
      end

      it "saves content for section to Publishing API with major update_type" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE),
        )

        subject.save_draft(manual)
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

        subject.save_draft(manual)
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

        subject.save_draft(manual)
      end
    end
  end

  describe "#unpublish" do
    before do
      manual.sections = [section]

      allow(publishing_api).to receive(:unpublish).with(anything, anything)
    end

    it "unpublishes manual via Publishing API" do
      expect(publishing_api).to receive(:unpublish).with(manual_id, type: "gone")

      subject.unpublish(manual)
    end

    it "unpublishes all manual's sections via Publishing API" do
      expect(publishing_api).to receive(:unpublish).with(section_uuid, type: "gone")

      subject.unpublish(manual)
    end
  end

  describe "#publish" do
    let(:removed_section_uuid) { "c146f39b-6512-4e3c-8991-fedda0b02a28" }

    let(:removed_section) do
      Section.new(
        manual: manual,
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

      subject.publish(manual)
    end

    it "publishes all manual's sections to Publishing API" do
      expect(publishing_api).to receive(:publish).with(section_uuid, nil)

      subject.publish(manual)
    end

    it "marks all manual's sections as exported" do
      expect(section).to receive(:mark_as_exported!)

      subject.publish(manual)
    end

    it "unpublishes all manual's removed sections via Publishing API" do
      expect(publishing_api).to receive(:unpublish).with(
        removed_section_uuid,
        type: "redirect",
        alternative_path: "/manual-slug",
        discard_drafts: true,
      )

      subject.publish(manual)
    end

    it "withdraws & marks all manual's removed sections as exported" do
      expect(removed_section).to receive(:withdraw_and_mark_as_exported!)

      subject.publish(manual)
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

        subject.publish(manual)
      end
    end

    context "when action is republish" do
      it "publishes manual to Publishing API with update type set to republish" do
        expect(publishing_api).to receive(:publish).with(manual_id, "republish")

        subject.publish(manual, republish: true)
      end

      it "publishes all manual's sections to Publishing API with update type set to republish" do
        expect(publishing_api).to receive(:publish).with(section_uuid, "republish")

        subject.publish(manual, republish: true)
      end

      it "does not mark all manual's sections as exported" do
        expect(section).not_to receive(:mark_as_exported!)

        subject.publish(manual, republish: true)
      end

      it "unpublishes all manual's removed sections via Publishing API" do
        expect(publishing_api).to receive(:unpublish).with(
          removed_section_uuid,
          anything,
        )

        subject.publish(manual, republish: true)
      end

      it "does not mark all manual's removed sections as exported" do
        expect(removed_section).not_to receive(:withdraw_and_mark_as_exported!)

        subject.publish(manual, republish: true)
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

          subject.publish(manual, republish: true)
        end
      end
    end
  end

  describe "#discard" do
    before do
      manual.sections = [section]

      allow(publishing_api).to receive(:discard_draft).with(anything)
    end

    it "discards draft manual via Publishing API" do
      expect(publishing_api).to receive(:discard_draft).with(manual_id)

      subject.discard(manual)
    end

    it "discards all manual's draft sections via Publishing API" do
      expect(publishing_api).to receive(:discard_draft).with(section_uuid)

      subject.discard(manual)
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

      subject.redirect_section(section, to: "/new-location")
    end

    it "redirects section via Publishing API with attributes which are valid according to redirect schema" do
      expect(publishing_api).to receive(:put_content).with(
        redirect_content_id,
        attributes_valid_according_to_schema("redirect"),
      )

      subject.redirect_section(manual, to: "/new-location")
    end
  end

  describe "#discard_draft_section" do
    it "discards draft section via Publishing API" do
      expect(publishing_api).to receive(:discard_draft).with(section_uuid)

      subject.discard_section(section)
    end
  end

private

  def attributes_valid_according_to_schema(schema_name)
    be_valid_against_schema(schema_name)
  end

  def attributes_valid_according_to_links_schema(schema_name)
    be_valid_against_links_schema(schema_name)
  end
end
