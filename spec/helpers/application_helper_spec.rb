describe ApplicationHelper, type: :helper do
  describe "#allow_publish?" do
    let(:manual) { instance_double(Manual) }

    before do
      @slug_unique = true
      allow(manual).to receive(:draft?).and_return(true)
      allow(manual).to receive_message_chain("sections.any?") { true }
    end

    context "when the current user can publish" do
      def current_user_can_publish? = true

      it "returns true when the manual may be published" do
        allowed = allow_publish?(manual, @slug_unique)

        expect(allowed).to be true
      end

      it "returns false when the manual is not in draft" do
        allow(manual).to receive(:draft?).and_return(false)

        allowed = allow_publish?(manual, @slug_unique)

        expect(allowed).to be false
      end

      it "returns false when the manual does not contain any sections" do
        allow(manual).to receive_message_chain("sections.any?") { false }

        allowed = allow_publish?(manual, @slug_unique)

        expect(allowed).to be false
      end

      it "returns false when the manual's slug is not unique" do
        @slug_unique = false

        allowed = allow_publish?(manual, @slug_unique)

        expect(allowed).to be false
      end
    end

    context "when the current user cannot publish" do
      def current_user_can_publish? = false

      it "returns false" do
        allowed = allow_publish?(manual, @slug_unique)

        expect(allowed).to be false
      end
    end
  end

  describe "#last_updated_text" do
    let(:section) { instance_double(Section, updated_at: Time.zone.now) }

    context "when section is not in draft state" do
      before do
        allow(section).to receive(:draft?).and_return(false)
      end

      it "returns text without author" do
        text = last_updated_text(section)

        expect(text).to eq("Updated less than a minute ago")
      end
    end

    context "when section is in draft state" do
      before do
        allow(section).to receive(:draft?).and_return(true)
      end

      it "returns text including author, when the author is known" do
        allow(section).to receive(:last_updated_by).and_return("Test User")

        text = last_updated_text(section)

        expect(text).to eq("Updated less than a minute ago by Test User")
      end

      it "returns text without author, when the author is not known" do
        allow(section).to receive(:last_updated_by).and_return(nil)

        text = last_updated_text(section)

        expect(text).to eq("Updated less than a minute ago")
      end
    end
  end

  describe "#state_label" do
    it "returns a span with general tag classes" do
      manual = FactoryBot.build_stubbed(:manual)

      result = state_label(manual)

      expect(result).to include("govuk-tag govuk-tag--s")
    end

    context "when manual is in draft state and has been published" do
      let(:manual) { FactoryBot.build_stubbed(:manual, state: "draft", ever_been_published: true) }

      it "returns a span with blue class" do
        result = state_label(manual)

        expect(result).to include("govuk-tag--blue")
      end

      it "appends text to publication state text" do
        result = state_label(manual)

        expect(result).to include("published with new draft")
      end
    end

    context "when manual is in draft state and has never been published" do
      let(:manual) { FactoryBot.build_stubbed(:manual, state: "draft", ever_been_published: false) }

      it "returns a span with blue class" do
        result = state_label(manual)

        expect(result).to include("govuk-tag--blue")
      end
    end

    context "when manual is in published state" do
      let(:manual) { FactoryBot.build_stubbed(:manual, state: "published") }

      it "returns a span with green class for an unedited published manual" do
        result = state_label(manual)

        expect(result).to include("govuk-tag--green")
      end
    end

    context "when manual is in withdrawn state" do
      let(:manual) { FactoryBot.build_stubbed(:manual, state: "withdrawn") }

      it "returns a span with grey class for an unedited published manual" do
        result = state_label(manual)

        expect(result).to include("govuk-tag--grey")
      end
    end
  end

  describe "#manual_metadata_rows" do
    before do
      allow_any_instance_of(ApplicationHelper).to receive(:current_user_is_gds_editor?).and_return(false)
    end

    it "returns a 'status' row" do
      manual = FactoryBot.build_stubbed(:manual)
      allow_any_instance_of(ApplicationHelper).to receive(:state_label).and_return("state_label")
      manual.publish_tasks = []

      rows = manual_metadata_rows(manual)

      expect(rows).to include(
        { key: "Status", value: "state_label" },
      )
    end

    it "returns a 'from' row when the current user is a gds editor" do
      organisation_slug = "Organisational slug"
      manual = FactoryBot.build_stubbed(:manual, organisation_slug:)
      allow_any_instance_of(ApplicationHelper).to receive(:current_user_is_gds_editor?).and_return(true)
      allow_any_instance_of(ApplicationHelper).to receive(:url_for_public_org).and_return("government/organisation_slug")
      manual.publish_tasks = []

      rows = manual_metadata_rows(manual)

      expect(rows).to include(
        { key: "From", value: link_to(manual.organisation_slug, "government/organisation_slug", class: "govuk-link") },
      )
    end

    it "does not return a 'from' row when the current user is not a gds editor" do
      organisation_slug = "Organisational slug"
      manual = FactoryBot.build_stubbed(:manual, organisation_slug:)
      allow_any_instance_of(ApplicationHelper).to receive(:current_user_is_gds_editor?).and_return(false)
      manual.publish_tasks = []

      rows = manual_metadata_rows(manual)

      expect(rows).not_to include(include(key: "From"))
    end

    it "returns an 'originally published' row when the manual has an original publication date" do
      manual = FactoryBot.build_stubbed(:manual, originally_published_at: Time.zone.now)
      allow_any_instance_of(ApplicationHelper).to receive(:nice_time_format).and_return("nice time format")
      allow_any_instance_of(ApplicationHelper).to receive(:original_publication_date_manual_path).and_return("original publication date path")
      manual.publish_tasks = []

      rows = manual_metadata_rows(manual)

      expect(rows).to include(
        { key: "Originally published",
          value: "nice time format" },
      )
    end

    it "does not return an 'originally published' row when the manual does not have an original publication date" do
      manual = FactoryBot.build_stubbed(:manual)
      manual.publish_tasks = []

      rows = manual_metadata_rows(manual)

      expect(rows).not_to include(include(key: "Originally published"))
    end

    it "returns a 'last published' row with the most recent publication date when the manual has been published" do
      manual = FactoryBot.build_stubbed(:manual, use_originally_published_at_for_public_timestamp: false)
      most_recent_publish_task = { updated_at: Time.zone.now, state: "queued" }
      manual.publish_tasks = [
        most_recent_publish_task,
        { updated_at: Time.zone.now - 10, state: "finished" },
      ]
      allow_any_instance_of(ApplicationHelper).to receive(:publication_task_state)
                                                    .with(most_recent_publish_task)
                                                    .and_return("test publication task state")

      rows = manual_metadata_rows(manual)

      expect(rows).to include(
        { key: "Last published",
          value: "test publication task state" },
      )
    end

    it "does not return a 'last published' row when the manual has not been published" do
      manual = FactoryBot.build_stubbed(:manual)
      manual.publish_tasks = []

      rows = manual_metadata_rows(manual)

      expect(rows).not_to include(include(key: "Last published"))
    end

    it "indicates when 'originally published at' will be used as the public timestamp" do
      manual = FactoryBot.build_stubbed(:manual, use_originally_published_at_for_public_timestamp: true)
      allow_any_instance_of(ApplicationHelper).to receive(:publication_task_state).and_return("test publication task state")
      manual.publish_tasks = [{ updated_at: Time.zone.now, state: "queued" }]

      rows = manual_metadata_rows(manual)

      expect(rows).to include(
        { key: "Last published",
          value: "test publication task state<br>This will be used as the public updated at timestamp on GOV.UK." },
      )
    end
  end

  describe "#manual_front_page_rows" do
    it "returns rows for slug, title, and summary" do
      slug = "/test-slug"
      title = "test title"
      summary = "test summary"
      manual = FactoryBot.build_stubbed(:manual, slug:, title:, summary:)

      rows = manual_front_page_rows(manual)

      expect(rows).to include(
        { key: "Slug", value: slug },
        { key: "Title", value: title },
        { key: "Summary", value: summary },
      )
    end

    it "returns a simple-formatted row for the body when it is not empty" do
      manual = FactoryBot.build_stubbed(:manual, body: "a manual body")

      rows = manual_front_page_rows(manual)

      expect(rows).to include(
        { key: "Body", value: "<p>a manual body</p>" },
      )
    end

    it "does not return a row for the body when it is empty" do
      manual = FactoryBot.build_stubbed(:manual, body: "")

      rows = manual_front_page_rows(manual)

      expect(rows).to_not include(include(key: "Body"))
    end
  end

  describe "#manual_sidebar_action_items" do
    before do
      allow_any_instance_of(ApplicationHelper).to receive(:allow_publish?).and_return(true)
    end

    it "returns a 'publish' button when the manual is allowed to be published" do
      manual = FactoryBot.build_stubbed(:manual)
      confirm_publish_path = "/manual/blah/confirm_publish"
      allow_any_instance_of(ApplicationHelper).to receive(:allow_publish?).and_return(true)
      allow_any_instance_of(ApplicationHelper).to receive(:confirm_publish_manual_path).and_return(confirm_publish_path)

      items = manual_sidebar_action_items(manual, true)

      expect(items).to include(include("Publish"))
      expect(items).to include(include(confirm_publish_path))
    end

    it "does not return a 'publish' button when the manual is not allowed to be published" do
      manual = FactoryBot.build_stubbed(:manual)
      allow_any_instance_of(ApplicationHelper).to receive(:allow_publish?).and_return(false)

      items = manual_sidebar_action_items(manual, true)

      expect(items).not_to include(include("Publish"))
    end

    it "returns a 'discard' button when the manual has never been published" do
      manual = FactoryBot.build_stubbed(:manual, ever_been_published: false)

      items = manual_sidebar_action_items(manual, true)

      expect(items).to include(include("Discard"))
    end

    it "does not return a 'discard' button when the manual has been published" do
      manual = FactoryBot.build_stubbed(:manual, ever_been_published: true)

      items = manual_sidebar_action_items(manual, true)

      expect(items).not_to include(include("Discard"))
    end
  end

  describe "#manual_section_rows" do
    before do
      allow_any_instance_of(ApplicationHelper).to receive(:last_updated_text).and_return("")
    end

    it "returns a row for each section in the manual" do
      manual = FactoryBot.build_stubbed(:manual)
      manual.build_section({ title: "test title" })
      manual.build_section({ title: "test title" })

      rows = manual_section_rows(manual)

      expect(rows.length).to be(2)
    end

    it "adds a 'DRAFT' tag to the key when the section is in the 'draft' state" do
      manual = FactoryBot.build_stubbed(:manual)
      manual.build_section({ state: "draft", title: "test title" })

      rows = manual_section_rows(manual)

      expect(rows).to include(include(key: include(">DRAFT</span>")))
      expect(rows).to include(include(key: include(">test title</span>")))
    end

    it "does not add a 'DRAFT' tag to the key when the section is in the 'published' state" do
      manual = FactoryBot.build_stubbed(:manual)
      manual.build_section({ state: "published", title: "test title" })

      rows = manual_section_rows(manual)

      expect(rows).not_to include(include(key: include(">DRAFT</span>")))
      expect(rows).to include(include(key: include(">test title</span>")))
    end

    it "uses the section's title for the key when the section is in the 'published state" do
      manual = FactoryBot.build_stubbed(:manual)
      manual.build_section({ state: "published", title: "test title" })

      rows = manual_section_rows(manual)

      expect(rows).to include(include(key: "<span>test title</span>"))
    end
  end

  describe "#publish_text" do
    it "returns correct text if the manual is published" do
      manual = FactoryBot.build_stubbed(:manual, state: "published")
      expect(publish_text(manual, "unique_slug")).to include("There are no changes to publish.")
    end

    it "returns correct text if the manual is withdrawn" do
      manual = FactoryBot.build_stubbed(:manual, state: "withdrawn")
      expect(publish_text(manual, "unique_slug")).to include("The manual is withdrawn. You need to create a new draft before it can be published.")
    end

    it "returns correct text if the current user cannot publish" do
      manual = FactoryBot.build_stubbed(:manual, state: "draft")
      allow_any_instance_of(ApplicationHelper).to receive(:current_user_can_publish?).and_return(false)
      expect(publish_text(manual, "unique_slug")).to include("You don't have permission to publish this manual.")
    end

    it "returns correct text if the slug is not unique" do
      manual = FactoryBot.build_stubbed(:manual, state: "draft")
      allow_any_instance_of(ApplicationHelper).to receive(:current_user_can_publish?).and_return(true)
      expect(publish_text(manual, false)).to include("This manual has a duplicate slug and can't be published.")
    end

    it "returns correct text if the change type is minor" do
      manual = FactoryBot.build_stubbed(:manual, state: "draft", ever_been_published: true)
      manual.build_section({ state: "draft", title: "test title", minor_update: true, version_number: 2 })
      allow_any_instance_of(ApplicationHelper).to receive(:current_user_can_publish?).and_return(true)
      expect(publish_text(manual, "slug_unique")).to include("You are about to publish a <strong>minor edit</strong>.")
    end

    it "returns correct text if the change type is major" do
      manual = FactoryBot.build_stubbed(:manual, state: "draft", ever_been_published: true)
      manual.build_section({ state: "draft", title: "test title", minor_update: false })
      allow_any_instance_of(ApplicationHelper).to receive(:current_user_can_publish?).and_return(true)
      expect(publish_text(manual, "slug_unique")).to include("<strong>You are about to publish a major edit with public change notes.</strong>")
    end

    it "returns correct text if the change type is major, use_originally_published_at_for_public_timestamp is true and originally_published_at is present" do
      manual = FactoryBot.build_stubbed(:manual, state: "draft", ever_been_published: true, use_originally_published_at_for_public_timestamp: true, originally_published_at: Time.zone.now)
      manual.build_section({ state: "draft", title: "test title", minor_update: false })
      allow_any_instance_of(ApplicationHelper).to receive(:current_user_can_publish?).and_return(true)
      expect(publish_text(manual, "slug_unique").length).to be(2)
      expect(publish_text(manual, "slug_unique")).to include("<strong>You are about to publish a major edit with public change notes.</strong>")
      expect(publish_text(manual, "slug_unique")).to include("The updated timestamp on GOV.UK will be set to the first publication date.")
    end

    it "returns correct text if the change type is minor, use_originally_published_at_for_public_timestamp is false and manual.version_type is minor" do
      manual = FactoryBot.build_stubbed(:manual, state: "draft", ever_been_published: true, use_originally_published_at_for_public_timestamp: false)
      manual.build_section({ state: "draft", title: "test title", minor_update: true, version_number: 2 })
      allow_any_instance_of(ApplicationHelper).to receive(:current_user_can_publish?).and_return(true)
      expect(publish_text(manual, "slug_unique").length).to be(2)
      expect(publish_text(manual, "slug_unique")).to include("You are about to publish a <strong>minor edit</strong>.")
      expect(publish_text(manual, "slug_unique")).to include("The updated timestamp on GOV.UK will not change.")
    end

    it "returns correct text if the change type is major, use_originally_published_at_for_public_timestamp is false and manual.version_type is minor" do
      manual = FactoryBot.build_stubbed(:manual, state: "draft", ever_been_published: true, use_originally_published_at_for_public_timestamp: false)
      manual.build_section({ state: "draft", title: "test title" })
      allow_any_instance_of(ApplicationHelper).to receive(:current_user_can_publish?).and_return(true)
      expect(publish_text(manual, "slug_unique").length).to be(2)
      expect(publish_text(manual, "slug_unique")).to include("<strong>You are about to publish a major edit with public change notes.</strong>")
      expect(publish_text(manual, "slug_unique")).to include("The updated timestamp on GOV.UK will be set to the time you press the publish button.")
    end
  end
end
