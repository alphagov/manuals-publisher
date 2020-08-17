require "spec_helper"
require "gds_api_constants"

describe ManualRelocator do
  include GdsApi::TestHelpers::PublishingApi
  include GdsApi::TestHelpers::Organisations
  let(:existing_manual_id) { SecureRandom.uuid }
  let(:temp_manual_id) { SecureRandom.uuid }
  let(:existing_slug) { "guidance/real-slug" }
  let(:temp_slug) { "guidance/temporary-slug" }
  subject { described_class.new(temp_slug, existing_slug) }

  describe "#move!" do
    let!(:existing_manual) { ManualRecord.create(manual_id: existing_manual_id, slug: existing_slug, organisation_slug: "cabinet-office") }
    let!(:temp_manual) { ManualRecord.create(manual_id: temp_manual_id, slug: temp_slug, organisation_slug: "cabinet-office") }
    let!(:existing_section1) { FactoryBot.create(:section_edition, slug: "#{existing_slug}/existing_section1", section_uuid: "12345", version_number: 1, state: "published", exported_at: Time.zone.now) }
    let!(:existing_section2) { FactoryBot.create(:section_edition, slug: "#{existing_slug}/existing_section2", section_uuid: "23456", version_number: 1, state: "published", exported_at: Time.zone.now) }
    let!(:temporary_section1) { FactoryBot.create(:section_edition, slug: "#{temp_slug}/temp_section1", section_uuid: "abcdef", version_number: 1, state: "published", exported_at: Time.zone.now) }
    let!(:temporary_section2) { FactoryBot.create(:section_edition, slug: "#{temp_slug}/temp_section2", section_uuid: "bcdefg", version_number: 1, state: "published", exported_at: Time.zone.now) }

    let!(:existing_section3) { FactoryBot.create(:section_edition, slug: "#{existing_slug}/section3", section_uuid: "34567", version_number: 1, state: "published", exported_at: Time.zone.now) }
    let!(:temporary_section3) { FactoryBot.create(:section_edition, slug: "#{temp_slug}/section3", section_uuid: "cdefgh", version_number: 1, state: "published", exported_at: Time.zone.now) }

    let!(:existing_publication_log) { FactoryBot.create(:publication_log, slug: "#{existing_slug}/slug-for-existing-section", change_note: "Hello from #{existing_manual_id}") }
    let!(:temporary_publication_log) { FactoryBot.create(:publication_log, slug: "#{temp_slug}/slug-for-temp-section", change_note: "Hello from #{temp_manual_id}") }

    before do
      allow(STDOUT).to receive(:puts)
      stub_organisations_api_has_organisation(temp_manual.organisation_slug)
      stub_any_publishing_api_publish
      stub_any_publishing_api_unpublish
      stub_any_publishing_api_put_content
    end

    context "validating manuals can be relocated" do
      it "raises an error if the existing manual has never been published" do
        existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 1, state: "draft")

        expect {
          subject.move!
        }.to raise_error(RuntimeError, "Manual to remove (#{existing_slug}) should be published")
      end

      it "raises an error if the existing manual has been published, but is currently withdrawn" do
        existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 1, state: "published")
        existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 2, state: "withdrawn")

        expect {
          subject.move!
        }.to raise_error(RuntimeError, "Manual to remove (#{existing_slug}) should be published")
      end

      it "raises an error if the temporary manual has never been published" do
        existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 1, state: "published")
        temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 1, state: "draft")

        expect {
          subject.move!
        }.to raise_error(RuntimeError, "Manual to reslug (#{temp_slug}) should be published")
      end

      it "raises an error if the temporary manual has been published, but is currently withdrawn" do
        existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 1, state: "published")
        temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 1, state: "published")
        temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 2, state: "withdrawn")

        expect {
          subject.move!
        }.to raise_error(RuntimeError, "Manual to reslug (#{temp_slug}) should be published")
      end

      it "does not raises an error if the existing manual is currently published" do
        existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 1, state: "published")
        temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 1, state: "published")

        expect {
          subject.move!
        }.not_to raise_error
      end

      context "if the existing manual is currently published" do
        let(:previous_edition) do
          ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 1)
        end

        before do
          existing_manual.editions << previous_edition
          existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 2, state: "published")
          temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 2, state: "published")
        end

        it "does not raises an error even if previous edition is withdrawn" do
          previous_edition.set(state: "withdrawn")
          expect {
            subject.move!
          }.not_to raise_error
        end

        it "does not raises an error even if previous edition is published" do
          previous_edition.set(state: "published")
          expect {
            subject.move!
          }.not_to raise_error
        end

        it "does not raises an error even if previous edition is draft" do
          previous_edition.set(state: "draft")
          expect {
            subject.move!
          }.not_to raise_error
        end
      end

      it "does not raises an error if the existing manual has previously been published, but is currently draft" do
        existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 1, state: "published")
        existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 2, state: "draft")
        temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 1, state: "published")

        expect {
          subject.move!
        }.not_to raise_error
      end

      it "does not raises an error if the temp manual is currently published" do
        existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 1, state: "published")
        temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 1, state: "published")

        expect {
          subject.move!
        }.not_to raise_error
      end

      context "if the temp manual is currently published" do
        let(:previous_edition) do
          ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 1)
        end

        before do
          existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 1, state: "published")
          temp_manual.editions << previous_edition
          temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 2, state: "published")
        end

        it "does not raises an error even if previous edition is withdrawn" do
          previous_edition.set(state: "withdrawn")
          expect {
            subject.move!
          }.not_to raise_error
        end

        it "does not raises an error even if previous edition is published" do
          previous_edition.set(state: "published")
          expect {
            subject.move!
          }.not_to raise_error
        end

        it "does not raises an error even if previous edition is draft" do
          previous_edition.set(state: "draft")
          expect {
            subject.move!
          }.not_to raise_error
        end
      end

      it "does not raises an error if the temp manual has previously been published, but is currently draft" do
        existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], state: "published")
        temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 1, state: "published")
        temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 2, state: "draft")

        expect {
          subject.move!
        }.not_to raise_error
      end
    end

    context "with valid manuals" do
      before do
        existing_manual.editions << ManualRecord::Edition.new(section_uuids: %w[12345 23456 34567], version_number: 1, state: "published")
      end

      shared_examples_for "removing the existing manual" do
        it "destroys the existing manual" do
          expect {
            existing_manual.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end

        it "replaces the existing manual with a gone item" do
          gone_object = {
            base_path: "/#{existing_slug}",
            content_id: existing_manual_id,
            document_type: "gone",
            publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
            schema_name: "gone",
            routes: [
              {
                path: "/#{existing_slug}",
                type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
              },
            ],
          }

          assert_publishing_api_put_content(existing_manual_id, request_json_matches(gone_object))
          assert_publishing_api_publish(existing_manual_id)
        end

        it "unpublishes the existing manual's sections with redirects to the existing slug" do
          assert_publishing_api_unpublish(
            existing_section1.section_uuid,
            type: "redirect",
            alternative_path: "/#{existing_slug}",
            discard_drafts: true,
          )

          assert_publishing_api_unpublish(
            existing_section2.section_uuid,
            type: "redirect",
            alternative_path: "/#{existing_slug}",
            discard_drafts: true,
          )
        end

        it "issues a gone for existing manual's sections that would be reused one of the new manual's sections" do
          gone_object = {
            base_path: "/#{existing_section3.slug}",
            content_id: existing_section3.section_uuid,
            document_type: "gone",
            publishing_app: GdsApiConstants::PublishingApi::PUBLISHING_APP,
            schema_name: "gone",
            routes: [
              {
                path: "/#{existing_section3.slug}",
                type: GdsApiConstants::PublishingApi::EXACT_ROUTE_TYPE,
              },
            ],
          }

          assert_publishing_api_put_content(existing_section3.section_uuid, request_json_matches(gone_object))
          assert_publishing_api_publish(existing_section3.section_uuid)
        end

        it "destroys the existing manual's sections" do
          expect {
            existing_section1.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)

          expect {
            existing_section2.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)

          expect {
            existing_section3.reload
          }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end

        it "removes the publication logs for the existing manual" do
          expect { existing_publication_log.reload }.to raise_error(Mongoid::Errors::DocumentNotFound)
        end
      end

      context "when the temp manual has no draft" do
        before do
          temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], version_number: 1, state: "published")
          subject.move!
        end

        it_behaves_like "removing the existing manual"

        it "moves the temporary manual to the existing slug" do
          expect(temp_manual.reload.slug).to eq(existing_slug)
          expect(ManualRecord.where(slug: temp_slug).count).to be(0)
        end

        it "unpublishes the temporary manual with a redirect to the existing slug" do
          assert_publishing_api_unpublish(
            temp_manual_id,
            type: "redirect",
            alternative_path: "/#{existing_slug}",
            discard_drafts: true,
          )
        end

        it "moves the temporary manual's sections to the existing slug" do
          expect(temporary_section1.reload.slug).to eq("#{existing_slug}/temp_section1")
          expect(temporary_section2.reload.slug).to eq("#{existing_slug}/temp_section2")
          expect(temporary_section3.reload.slug).to eq("#{existing_slug}/section3")
          expect(SectionEdition.where(slug: /#{temp_slug}/).count).to be(0)
        end

        it "unpublishes the temporary manual's section slugs with redirects to their existing slug version" do
          assert_publishing_api_unpublish(
            temporary_section1.section_uuid,
            type: "redirect",
            alternative_path: "/#{existing_slug}/temp_section1",
            discard_drafts: true,
          )

          assert_publishing_api_unpublish(
            temporary_section2.section_uuid,
            type: "redirect",
            alternative_path: "/#{existing_slug}/temp_section2",
            discard_drafts: true,
          )

          assert_publishing_api_unpublish(
            temporary_section3.section_uuid,
            type: "redirect",
            alternative_path: "/#{existing_slug}/section3",
            discard_drafts: true,
          )
        end

        it "sends a new draft of the temporary manual with the existing slug as a route" do
          assert_publishing_api_put_content(temp_manual_id, with_route_matcher("/#{existing_slug}"))
        end

        it "sends a publish request for the temporary manual" do
          assert_publishing_api_publish(temp_manual_id)
        end

        it "sends a new draft of each of the temporary manual's sections with the existing slug version of their path as a route" do
          assert_publishing_api_put_content(temporary_section1.section_uuid, with_route_matcher("/#{existing_slug}/temp_section1"))
          assert_publishing_api_put_content(temporary_section2.section_uuid, with_route_matcher("/#{existing_slug}/temp_section2"))
          assert_publishing_api_put_content(temporary_section3.section_uuid, with_route_matcher("/#{existing_slug}/section3"))
        end

        it "sends a publish request for each of the temporary manual's sections" do
          assert_publishing_api_publish(temporary_section1.section_uuid)
          assert_publishing_api_publish(temporary_section2.section_uuid)
          assert_publishing_api_publish(temporary_section3.section_uuid)
        end
      end

      context "when the temp manual has a draft" do
        let!(:temporary_section1_v2) { FactoryBot.create(:section_edition, slug: "#{temp_slug}/temp_section1", section_uuid: "abcdef", version_number: 2, state: "draft", body: temporary_section1.body.reverse) }
        let!(:temporary_section2_v2) { FactoryBot.create(:section_edition, slug: "#{temp_slug}/temp_section2", section_uuid: "bcdefg", version_number: 2, state: "draft", body: temporary_section2.body.reverse) }

        before do
          temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg], state: "published", version_number: 1, body: "This has been published")
          temp_manual.editions << ManualRecord::Edition.new(section_uuids: %w[abcdef bcdefg cdefgh], state: "draft", version_number: 2, body: "This is in draft")
          subject.move!
        end

        it_behaves_like "removing the existing manual"

        it "moves the temporary manual to the existing slug" do
          expect(temp_manual.reload.slug).to eq(existing_slug)
          expect(ManualRecord.where(slug: temp_slug).count).to be(0)
        end

        it "unpublishes the temporary manual with a redirect to the existing slug" do
          assert_publishing_api_unpublish(
            temp_manual_id,
            type: "redirect",
            alternative_path: "/#{existing_slug}",
            discard_drafts: true,
          )
        end

        it "moves the temporary manual's sections to the existing slug" do
          expect(temporary_section1.reload.slug).to eq("#{existing_slug}/temp_section1")
          expect(temporary_section2.reload.slug).to eq("#{existing_slug}/temp_section2")
          expect(temporary_section3.reload.slug).to eq("#{existing_slug}/section3")
          expect(SectionEdition.where(slug: /#{temp_slug}/).count).to be(0)
        end

        it "unpublishes the temporary manual's section slugs with redirects to their existing slug version" do
          assert_publishing_api_unpublish(
            temporary_section1.section_uuid,
            type: "redirect",
            alternative_path: "/#{existing_slug}/temp_section1",
            discard_drafts: true,
          )

          assert_publishing_api_unpublish(
            temporary_section2.section_uuid,
            type: "redirect",
            alternative_path: "/#{existing_slug}/temp_section2",
            discard_drafts: true,
          )

          assert_publishing_api_unpublish(
            temporary_section3.section_uuid,
            type: "redirect",
            alternative_path: "/#{existing_slug}/section3",
            discard_drafts: true,
          )
        end

        it "sends a draft of the published version of the temporary manual with the existing slug as a route" do
          assert_publishing_api_put_content(temp_manual_id, with_body_and_route_matcher("This has been published", "/#{existing_slug}"))
        end

        it "sends a publish request for the published version of the temporary manual" do
          assert_publishing_api_publish(temp_manual_id)
        end

        it "sends a draft of the draft version of the temporary manual with the existing slug as a route" do
          assert_publishing_api_put_content(temp_manual_id, with_body_and_route_matcher("This is in draft", "/#{existing_slug}"))
        end

        it "sends a draft of each of the temporary manual's published sections with the existing slug version of their path as a route" do
          assert_publishing_api_put_content(temporary_section1.section_uuid, with_body_and_route_matcher(temporary_section1.body, "/#{existing_slug}/temp_section1"))
          assert_publishing_api_put_content(temporary_section2.section_uuid, with_body_and_route_matcher(temporary_section2.body, "/#{existing_slug}/temp_section2"))
        end

        it "sends a publish request for each of the temporary manual's published sections" do
          assert_publishing_api_publish(temporary_section1.section_uuid)
          assert_publishing_api_publish(temporary_section2.section_uuid)
        end

        it "does not send a publish request for any section only present in the new draft" do
          assert_publishing_api_publish(temporary_section3.section_uuid, nil, 0)
        end

        it "sends a draft of each of the temporary manual's draft sections with the existing slug version of their path as a route" do
          assert_publishing_api_put_content(temporary_section1.section_uuid, with_body_and_route_matcher(temporary_section1_v2.body, "/#{existing_slug}/temp_section1"))
          assert_publishing_api_put_content(temporary_section2.section_uuid, with_body_and_route_matcher(temporary_section2_v2.body, "/#{existing_slug}/temp_section2"))
          assert_publishing_api_put_content(temporary_section3.section_uuid, with_body_and_route_matcher(temporary_section3.body, "/#{existing_slug}/section3"))
        end
      end
    end
  end

  def with_body_matcher(body)
    lambda do |request|
      data = JSON.parse(request.body)
      unrendered_body = data["details"]["body"].detect { |api_body| api_body["content_type"] == "text/govspeak" }
      (unrendered_body && unrendered_body["content"] == body)
    end
  end

  def with_body_and_route_matcher(body, path)
    lambda do |request|
      data = JSON.parse(request.body)
      routes = data["routes"]
      unrendered_body = data["details"]["body"].detect { |api_body| api_body["content_type"] == "text/govspeak" }
      (unrendered_body && unrendered_body["content"] == body) &&
        ((data["base_path"] == path) && (routes.any? { |route| route["path"] == path }))
    end
  end

  def with_route_matcher(path)
    lambda do |request|
      data = JSON.parse(request.body)
      routes = data["routes"]
      (data["base_path"] == path) && (routes.any? { |route| route["path"] == path })
    end
  end
end
