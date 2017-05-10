require "spec_helper"
require "gds_api_constants"

describe PublishingAdapter do
  let(:publishing_api_schema_name_for_manual) {
    GdsApiConstants::PublishingApiV2::MANUAL_SCHEMA_NAME
  }

  let(:publishing_api_document_type_for_manual) {
    GdsApiConstants::PublishingApiV2::MANUAL_DOCUMENT_TYPE
  }

  let(:publishing_api_schema_name_for_section) {
    GdsApiConstants::PublishingApiV2::SECTION_SCHEMA_NAME
  }

  let(:publishing_api_document_type_for_section) {
    GdsApiConstants::PublishingApiV2::SECTION_DOCUMENT_TYPE
  }

  let(:timestamp) { Time.zone.parse("2017-01-01 00:00:00") }

  let(:publishing_api) { double(:publishing_api) }
  let(:organisations) { double(:organisations_adapter) }

  let(:manual_id) { "a55242ed-178f-4716-8bb3-5d4f82d38531" }

  let(:manual) {
    Manual.build(
      id: manual_id,
      slug: "manual-slug",
      organisation_slug: "organisation-slug",
      title: "manual-title",
      summary: "manual-summary",
      body: "manual-body",
    )
  }

  let(:section_uuid) { "64dbf396-b637-40b7-ada4-f19ce460e5e9" }

  let(:section) {
    Section.new(
      manual: manual,
      uuid: section_uuid,
      editions: [section_edition],
    )
  }

  let(:section_edition) {
    SectionEdition.new(
      slug: "manual-slug/section-slug",
      title: "section-title",
      summary: "section-summary",
      body: "section-body"
    )
  }

  let(:organisation_content_id) { "afa741e9-c68e-4ade-bc8f-ceb1fced23a6" }

  let(:organisation) {
    Organisation.new(
      title: "organisation-title",
      abbreviation: "organisation-abbreviation",
      content_id: organisation_content_id,
      web_url: "organisation-web-url",
    )
  }

  let(:publication_logs) { [] }

  before do
    allow(Services).to receive(:publishing_api).and_return(publishing_api)
    allow(Adapters).to receive(:organisations).and_return(organisations)

    allow(PublicationLog).to receive(:change_notes_for).with("manual-slug")
      .and_return(publication_logs)
  end

  describe "#save" do
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
          sections: [section_uuid]
        }
      )

      subject.save(manual)
    end

    it "saves links for manual to Publishing API with valid attributes" do
      expect(publishing_api).to receive(:patch_links).with(
        manual_id,
        be_valid_against_links_schema(
          publishing_api_schema_name_for_manual
        )
      )

      subject.save(manual)
    end

    it "saves content for manual to Publishing API" do
      expect(publishing_api).to receive(:put_content).with(
        manual_id,
        base_path: "/manual-slug",
        schema_name: publishing_api_schema_name_for_manual,
        document_type: publishing_api_document_type_for_manual,
        title: "manual-title",
        description: "manual-summary",
        update_type: GdsApiConstants::PublishingApiV2::MAJOR_UPDATE_TYPE,
        publishing_app: GdsApiConstants::PublishingApiV2::PUBLISHING_APP,
        rendering_app: "manuals-frontend",
        routes: [
          {
            path: "/manual-slug",
            type: "exact",
          },
          {
            path: "/manual-slug/updates",
            type: "exact",
          }
        ],
        details: {
          body: [
            {
              content_type: "text/govspeak",
              content: "manual-body"
            },
            {
              content_type: "text/html",
              content: "<p>manual-body</p>\n"
            }
          ],
          child_section_groups:  [
            {
              title: "Contents",
              child_sections: [
                {
                  title: "section-title",
                  description: "section-summary",
                  base_path: "/manual-slug/section-slug",
                }
              ],
            }
          ],
          change_notes: [],
          organisations: [
            {
              title: "organisation-title",
              abbreviation: "organisation-abbreviation",
              web_url: "organisation-web-url",
            }
          ]
        },
        locale: "en",
      )

      subject.save(manual)
    end

    it "saves links for all manual's sections to Publishing API" do
      expect(publishing_api).to receive(:patch_links).with(
        section_uuid,
        links: {
          organisations: [organisation_content_id],
          manual: [manual_id]
        }
      )

      subject.save(manual)
    end

    it "saves links for all manual's sections to Publishing API with valid attributes" do
      expect(publishing_api).to receive(:patch_links).with(
        section_uuid,
        be_valid_against_links_schema(
          publishing_api_schema_name_for_section
        )
      )

      subject.save(manual)
    end

    it "saves content for all manual's sections to Publishing API" do
      expect(publishing_api).to receive(:put_content).with(
        section_uuid,
        base_path: "/manual-slug/section-slug",
        schema_name: publishing_api_schema_name_for_section,
        document_type: publishing_api_document_type_for_section,
        title: "section-title",
        description: "section-summary",
        update_type: GdsApiConstants::PublishingApiV2::MAJOR_UPDATE_TYPE,
        publishing_app: GdsApiConstants::PublishingApiV2::PUBLISHING_APP,
        rendering_app: "manuals-frontend",
        routes: [
          {
            path: "/manual-slug/section-slug",
            type: "exact"
          },
        ],
        details: {
          body: [
            {
              content_type: "text/govspeak",
              content: "section-body"
            },
            {
              content_type: "text/html",
              content: "<p>section-body</p>\n"
            }
          ],
          manual: {
            base_path: "/manual-slug",
          },
          organisations: [
            {
              title: "organisation-title",
              abbreviation: "organisation-abbreviation",
              web_url: "organisation-web-url"
            }
          ]
        },
        locale: "en",
      )

      subject.save(manual)
    end

    context "when section does not need exporting" do
      before do
        allow(section).to receive(:needs_exporting?).and_return(false)
      end

      it "does not save links for section to Publishing API" do
        expect(publishing_api).not_to receive(:patch_links).with(
          section_uuid,
          anything
        )

        subject.save(manual)
      end

      it "does not save content for section to Publishing API" do
        expect(publishing_api).not_to receive(:put_content).with(
          section_uuid,
          anything
        )

        subject.save(manual)
      end

      context "and action is republish" do
        it "saves links for section to Publishing API" do
          expect(publishing_api).to receive(:patch_links).with(
            section_uuid,
            anything
          )

          subject.save(manual, republish: true)
        end

        it "saves content for section to Publishing API" do
          expect(publishing_api).to receive(:put_content).with(
            section_uuid,
            anything
          )

          subject.save(manual, republish: true)
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
            first_published_at: timestamp.iso8601,
            public_updated_at: timestamp.iso8601
          ),
        )

        subject.save(manual)
      end

      it "saves content for section to Publishing API with timestamps" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(
            first_published_at: timestamp.iso8601,
            public_updated_at: timestamp.iso8601
          ),
        )

        subject.save(manual)
      end

      context "but Manual#use_originally_published_at_for_public_timestamp? is false" do
        before do
          allow(manual).to receive(:use_originally_published_at_for_public_timestamp?).and_return(false)
        end

        it "saves content for manual to Publishing API without public timestamp" do
          expect(publishing_api).to receive(:put_content).with(
            manual_id,
            excluding(
              public_updated_at: timestamp.iso8601
            ),
          )

          subject.save(manual)
        end

        it "saves content for section to Publishing API without public timestamp" do
          expect(publishing_api).to receive(:put_content).with(
            section_uuid,
            excluding(
              public_updated_at: timestamp.iso8601
            ),
          )

          subject.save(manual)
        end
      end
    end

    shared_examples_for "republishing overrides update_type" do
      context "when action is republish" do
        it "saves content for manual to Publishing API with republish update_type" do
          expect(publishing_api).to receive(:put_content).with(
            manual_id,
            including(update_type: GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE)
          )

          subject.save(manual, republish: true)
        end

        it "saves content for section to Publishing API with republish update_type" do
          expect(publishing_api).to receive(:put_content).with(
            section_uuid,
            including(update_type: GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE)
          )

          subject.save(manual, republish: true)
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
          including(update_type: GdsApiConstants::PublishingApiV2::MAJOR_UPDATE_TYPE)
        )

        subject.save(manual)
      end

      it "saves content for section to Publishing API with major update_type" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(update_type: GdsApiConstants::PublishingApiV2::MAJOR_UPDATE_TYPE)
        )

        subject.save(manual)
      end

      it_behaves_like "republishing overrides update_type"
    end

    context "when manual & section version_type are minor" do
      before do
        allow(manual).to receive(:version_type).and_return(:minor)
        allow(section).to receive(:version_type).and_return(:minor)
      end

      it "saves content for manual to Publishing API with minor update_type" do
        expect(publishing_api).to receive(:put_content).with(
          manual_id,
          including(update_type: GdsApiConstants::PublishingApiV2::MINOR_UPDATE_TYPE)
        )

        subject.save(manual)
      end

      it "saves content for section to Publishing API with minor update_type" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(update_type: GdsApiConstants::PublishingApiV2::MINOR_UPDATE_TYPE)
        )

        subject.save(manual)
      end

      it_behaves_like "republishing overrides update_type"
    end

    context "when manual & section version_type are major" do
      before do
        allow(manual).to receive(:version_type).and_return(:major)
        allow(section).to receive(:version_type).and_return(:major)
      end

      it "saves content for manual to Publishing API with major update_type" do
        expect(publishing_api).to receive(:put_content).with(
          manual_id,
          including(update_type: GdsApiConstants::PublishingApiV2::MAJOR_UPDATE_TYPE)
        )

        subject.save(manual)
      end

      it "saves content for section to Publishing API with major update_type" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(update_type: GdsApiConstants::PublishingApiV2::MAJOR_UPDATE_TYPE)
        )

        subject.save(manual)
      end

      it_behaves_like "republishing overrides update_type"
    end

    context "when publication logs exist for section" do
      let(:publication_log) {
        PublicationLog.new(
          title: "section-title",
          slug: "manual-slug/section-slug",
          change_note: "section-change-note",
          published_at: timestamp
        )
      }

      let(:publication_logs) { [publication_log] }

      it "saves content for manual to Publishing API including change notes" do
        expect(publishing_api).to receive(:put_content).with(
          manual_id,
          including(details: including(
            change_notes: [{
              title: "section-title",
              base_path: "/manual-slug/section-slug",
              change_note: "section-change-note",
              published_at: timestamp.iso8601
            }]
          ))
        )

        subject.save(manual)
      end
    end

    context "when section has attachments" do
      let(:another_timestamp) { timestamp + 1.day }

      let(:attachment) {
        Attachment.new(
          title: 'attachment-title',
          file_url: 'attachment-file-url.jpg',
          created_at: timestamp,
          updated_at: another_timestamp
        )
      }

      let(:attachments) { [attachment] }

      before do
        allow(section).to receive(:attachments).and_return(attachments)
        allow(SecureRandom).to receive(:uuid).and_return("attachment-content-id")
      end

      it "saves content for section to Publishing API including attachments" do
        expect(publishing_api).to receive(:put_content).with(
          section_uuid,
          including(details: including(
            attachments: [
              including(
                content_id: "attachment-content-id",
                title: "attachment-title",
                url: "attachment-file-url.jpg",
                created_at: timestamp,
                updated_at: another_timestamp,
                content_type: "application/jpg"
              )
            ]
          ))
        )

        subject.save(manual)
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
        publishing_app: GdsApiConstants::PublishingApiV2::PUBLISHING_APP,
        redirects: [
          {
            path: "/manual-slug/section-slug",
            type: "exact",
            destination: "/new-location"
          }
        ],
      )

      subject.redirect_section(section, to: "/new-location")
    end

    it "redirects section via Publishing API with valid attributes" do
      expect(publishing_api).to receive(:put_content).with(
        redirect_content_id,
        be_valid_against_schema("redirect")
      )

      subject.redirect_section(manual, to: "/new-location")
    end
  end
end
