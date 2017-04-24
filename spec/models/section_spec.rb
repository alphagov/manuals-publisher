require "spec_helper"

describe Section do
  subject(:section) {
    Section.new(slug_generator, section_id, editions, edition_factory)
  }

  def key_classes_for(hash)
    hash.keys.map(&:class).uniq
  end

  let(:section_id) { "a-section-id" }
  let(:slug) { double(:slug) }
  let(:published_slug) { double(:published_slug) }
  let(:slug_generator) { double(:slug_generator, call: slug) }
  let(:editions) { [] }
  let(:edition_factory) { double(:edition_factory, call: new_edition) }
  let(:new_edition) { double(:new_edition, published?: false, draft?: true, assign_attributes: nil, version_number: 2) }
  let(:attachments) { double(:attachments) }

  let(:edition_messages) {
    {
      build_attachment: nil,
      assign_attributes: nil,
      attachments: attachments_proxy,
      publish: nil,
      archive: nil,
      attributes: {},
      minor_update: false,
      change_note: "Some changes",
      :exported_at= => nil,
      save: nil,
    }
  }

  let(:attachments_proxy) { double(:attachments_proxy, to_a: attachments) }

  let(:draft_edition_v1) {
    double(:draft_edition_v1,
      edition_messages.merge(
        title: "Draft edition v1",
        state: "draft",
        draft?: true,
        published?: false,
        archived?: false,
        version_number: 1,
        exported_at: nil,
      )
    )
  }

  let(:draft_edition_v2) {
    double(:draft_edition_v2,
      edition_messages.merge(
        title: "Draft edition v2",
        state: "draft",
        draft?: true,
        published?: false,
        archived?: false,
        version_number: 2,
        exported_at: nil,
      )
    )
  }

  let(:draft_edition_v3) {
    double(:draft_edition_v3,
      edition_messages.merge(
        title: "Draft edition v3",
        state: "draft",
        draft?: true,
        published?: false,
        archived?: false,
        version_number: 3,
        exported_at: nil,
      )
    )
  }

  let(:published_edition_v1) {
    double(:published_edition_v1,
      edition_messages.merge(
        title: "Published edition",
        state: "published",
        published?: true,
        draft?: false,
        archived?: false,
        slug: published_slug,
        version_number: 1,
      )
    )
  }

  let(:withdrawn_edition_v2) {
    double(:withdrawn_edition_v2,
      edition_messages.merge(
        title: "Withdrawn edition",
        state: "withdrawn",
        published?: false,
        draft?: false,
        archived?: true,
        slug: published_slug,
        version_number: 2,
      )
    )
  }

  describe "#eql?" do
    let(:editions) { [draft_edition_v1] }

    it "is considered the same as another section instance if they have the same id" do
      expect(section).to eql(section)
      expect(section).to eql(Section.new(slug_generator, section.id, [draft_edition_v1]))
      expect(section).not_to eql(Section.new(slug_generator, section.id.reverse, [draft_edition_v1]))
    end

    it "is considered the same as another section instance with the same id even if they have different version numbers" do
      expect(section).to eql(Section.new(slug_generator, section.id, [draft_edition_v2]))
    end
  end

  context "with one draft edition" do
    let(:editions) { [draft_edition_v1] }

    it "is in draft" do
      expect(section).to be_draft
    end

    it "is not published" do
      expect(section).not_to be_published
    end

    it "has never been published" do
      expect(section).not_to have_ever_been_published
    end
  end

  context "with one published edition" do
    let(:editions) { [published_edition_v1] }

    it "is published" do
      expect(section).to be_published
    end

    it "is not in draft" do
      expect(section).not_to be_draft
    end

    context "that has been exported" do
      before { allow(published_edition_v1).to receive(:exported_at).and_return(4.days.ago) }

      it "has ever been published" do
        expect(section).to have_ever_been_published
      end
    end

    context "that has not been exported" do
      before { allow(published_edition_v1).to receive(:exported_at).and_return(nil) }

      it "has never been published" do
        expect(section).not_to have_ever_been_published
      end
    end
  end

  context "with one published edition and one draft edition" do
    let(:editions) { [published_edition_v1, draft_edition_v2] }

    it "is published and in draft" do
      expect(section).to be_draft
      expect(section).to be_published
    end

    it "has ever been published" do
      expect(section).to have_ever_been_published
    end
  end

  context "with two draft editions" do
    let(:editions) { [draft_edition_v1, draft_edition_v2] }

    it "is in draft" do
      expect(section).to be_draft
    end

    it "is not published" do
      expect(section).not_to be_published
    end

    it "has never been published" do
      expect(section).not_to have_ever_been_published
    end
  end

  context "with one draft edition and a withdrawn edition" do
    let(:editions) { [draft_edition_v1, withdrawn_edition_v2] }

    it "is not in draft" do
      expect(section).not_to be_draft
    end

    it "is not published" do
      expect(section).not_to be_published
    end

    it "has never been published" do
      expect(section).not_to have_ever_been_published
    end
  end

  describe "#update" do
    context "with string keyed attributes hashes" do
      let(:editions) { [draft_edition_v1] }
      let(:string_keyed_attrs) {
        {
          "body" => "o hai",
        }
      }

      it "symbolizes the keys" do
        section.update(string_keyed_attrs)

        expect(draft_edition_v1).to have_received(:assign_attributes).with(
          hash_including(body: "o hai")
        )
      end
    end

    context "with bad attributes hashes" do
      let(:editions) { [draft_edition_v1] }
      let(:bad_attrs) {
        {
          key_that_is_not_allowed: "o hai",
        }
      }

      it "cleans the hash" do
        section.update(bad_attrs)

        expect(draft_edition_v1).to have_received(:assign_attributes).with({})
      end
    end

    context "section is new, with no previous editions" do
      let(:editions) { [] }
      let(:attrs)    { { title: "Test title" } }

      it "creates the first edition" do
        section.update(attrs)

        expect(edition_factory).to have_received(:call).with(
          version_number: 1,
          state: "draft",
          section_id: section_id,
        )
      end
    end

    context "before the section is published" do
      context "with an existing draft edition" do
        let(:editions) { [draft_edition_v1] }

        context "when providing a title" do
          let(:new_title) { double(:new_title) }
          let(:slug)      { double(:slug) }

          it "generates a slug" do
            section.update(title: new_title)

            expect(slug_generator).to have_received(:call).with(new_title)
          end

          it "assigns the title and slug to the draft edition" do
            section.update(title: new_title)

            expect(draft_edition_v1).to have_received(:assign_attributes)
              .with(
                hash_including(
                  title: new_title,
                  slug: slug,
                )
              )
          end
        end
      end
    end

    context "when the current section is published" do
      let(:editions) { [published_edition_v1] }

      let(:params) { { title: "It is a new title" } }

      let(:edition_body) { double(:edition_body) }
      let(:edition_attributes) {
        {
          "_id" => "superfluous id",
          "updated_at" => "superfluous timestamp",
          "body" => edition_body,
        }
      }

      before do
        allow(published_edition_v1).to receive(:attributes)
          .and_return(edition_attributes)
      end

      it "builds a new edition with the new params" do
        section.update(params)

        expect(edition_factory).to have_received(:call).with(hash_including(params))
      end

      it "builds the new edition with attributes carried over from the previous edition" do
        section.update(params)

        expect(edition_factory).to have_received(:call)
          .with(hash_including(body: edition_body))
      end

      it "filters the previous edition's attributes" do
        section.update(params)

        expect(edition_factory).not_to have_received(:call)
          .with(
            hash_including(
              _id: "superfluous id",
              updated_at: "superfluous timestamp",
            )
          )

        expect(edition_factory).not_to have_received(:call)
          .with(
            hash_including(
              "_id" => "superfluous id",
              "updated_at" => "superfluous timestamp",
            )
          )
      end

      it "builds a new edition with an incremented version number" do
        section.update(params)

        expect(edition_factory).to have_received(:call).with(hash_including(version_number: 2))
      end

      it "builds a new edition in the 'draft' state" do
        section.update(params)

        expect(edition_factory).to have_received(:call).with(hash_including(state: "draft"))
      end

      it "builds a new edition copying over the previous edition's attachments" do
        section.update(params)

        expect(edition_factory).to have_received(:call)
          .with(hash_including(attachments: attachments))
      end

      it "presents the new edition" do
        section.update(params)

        expect(section.version_number).to eq(new_edition.version_number)
      end

      it "returns nil" do
        expect(section.update(params)).to eq(nil)
      end

      context "when providing a title" do
        let(:new_title) { double(:new_title) }
        let(:slug)      { double(:slug) }

        it "does not update the slug" do
          section.update(title: new_title)

          expect(edition_factory).to have_received(:call).with(
            hash_including(
              slug: published_slug,
            )
          )
        end
      end
    end

    context "when the current section is withdrawn" do
      let(:editions) { [withdrawn_edition_v2] }

      let(:params) { { title: "It is a new title" } }

      it "builds a new edition with the new params" do
        section.update(params)

        expect(edition_factory).to have_received(:call).with(hash_including(params))
      end

      it "builds a new edition with an incremented version number" do
        section.update(params)

        expect(edition_factory).to have_received(:call).with(hash_including(version_number: 3))
      end

      it "builds a new edition in the 'draft' state" do
        section.update(params)

        expect(edition_factory).to have_received(:call).with(hash_including(state: "draft"))
      end

      it "builds a new edition copying over the previous edition's attachments" do
        section.update(params)

        expect(edition_factory).to have_received(:call)
          .with(hash_including(attachments: attachments))
      end

      it "presents the new edition" do
        section.update(params)

        expect(section.version_number).to eq(new_edition.version_number)
      end

      it "returns nil" do
        expect(section.update(params)).to eq(nil)
      end

      context "when providing a title" do
        let(:new_title) { double(:new_title) }
        let(:slug)      { double(:slug) }

        it "does not update the slug" do
          section.update(title: new_title)

          expect(edition_factory).to have_received(:call).with(
            hash_including(
              slug: published_slug,
            )
          )
        end
      end
    end
  end

  describe "#publish!" do
    context "one draft" do
      let(:editions) { [draft_edition_v1] }

      it "should set its state to published" do
        section.publish!
        expect(draft_edition_v1).to have_received(:publish)
      end
    end

    context "one published and one draft edition" do
      let(:editions) { [published_edition_v1, draft_edition_v2] }

      it "should set the draft edition's state to published" do
        section.publish!
        expect(draft_edition_v2).to have_received(:publish)
      end

      it "archives the previous edition" do
        section.publish!

        expect(published_edition_v1).to have_received(:archive)
      end
    end

    context "one published edition" do
      let(:editions) { [published_edition_v1] }

      it "do nothing" do
        section.publish!
        expect(published_edition_v1).not_to have_received(:publish)
      end
    end
  end

  describe "#add_attachment" do
    let(:editions) { [published_edition_v1, draft_edition_v2] }
    let(:params) { double(:params) }

    it "tells the latest edition to create an attachment using the supplied parameters" do
      section.add_attachment(params)

      expect(draft_edition_v2).to have_received(:build_attachment).with(params)
    end
  end

  describe "#attachments" do
    let(:editions) { [published_edition_v1, draft_edition_v2] }

    it "delegates to the latest edition" do
      section.attachments

      expect(draft_edition_v2).to have_received(:attachments)
    end

    it "returns the attachments from the latest edition" do
      expect(section.attachments).to eq(attachments)
    end
  end

  describe "#attributes" do
    let(:relevant_section_attrs) {
      {
        "title" => "section_title",
      }
    }

    let(:undesirable_edtion_attrs) {
      {
        "junk_key" => "junk_value",
      }
    }

    let(:edition) {
      draft_edition_v2.tap do |e|
        allow(e).to receive(:attributes).and_return(relevant_section_attrs.merge(undesirable_edtion_attrs))
      end
    }

    let(:editions) { [published_edition_v1, edition] }

    it "symbolizes the keys" do
      expect(key_classes_for(section.attributes)).to eq([Symbol])
    end

    it "returns attributes with junk removed" do
      expect(section.attributes).not_to include(
        undesirable_edtion_attrs.symbolize_keys
      )
    end

    it "returns the latest edition's attributes" do
      expect(section.attributes).to include(
        relevant_section_attrs.symbolize_keys
      )
    end

    it "returns a has including the section's id" do
      expect(section.attributes).to include(
        id: section_id,
      )
    end
  end

  describe "#find_attachment_by_id" do
    let(:editions) { [published_edition_v1] }

    let(:attachment_one) { double("attachment_one", id: id_object("one")) }
    let(:attachment_two) { double("attachment_two", id: id_object("two")) }

    let(:attachments) {
      [
        attachment_one,
        attachment_two,
      ]
    }

    def id_object(id_string)
      # like a Mongoid BSON id
      double(to_s: id_string)
    end

    it "returns the attachment with the corresponding id" do
      expect(
        section.find_attachment_by_id("one")
      ).to eq(attachment_one)
    end

    it "returns nil if the attachment does not exist" do
      expect(
        section.find_attachment_by_id("does-not-exist")
      ).to be_nil
    end
  end

  describe "#publication_state" do
    context "when the first edition is in draft" do
      let(:editions) { [draft_edition_v1] }

      it "returns 'draft'" do
        expect(section.publication_state).to eq("draft")
      end
    end

    context "with a single published edition" do
      let(:editions) { [published_edition_v1] }

      it "returns 'published'" do
        expect(section.publication_state).to eq("published")
      end
    end

    context "with a single published edition" do
      let(:editions) { [published_edition_v1, draft_edition_v2] }

      it "returns 'published'" do
        expect(section.publication_state).to eq("published")
      end
    end

    context "with a published edition, and withdrawn edition" do
      let(:editions) { [published_edition_v1, withdrawn_edition_v2] }

      it "returns 'withdrawn'" do
        expect(section.publication_state).to eq("withdrawn")
      end
    end
  end

  describe "#withdrawn?" do
    context "one draft" do
      let(:editions) { [draft_edition_v1] }

      it "returns false" do
        expect(section).not_to be_withdrawn
      end
    end

    context "one published" do
      let(:editions) { [published_edition_v1] }

      it "returns false" do
        expect(section).not_to be_withdrawn
      end
    end

    context "one published and one withdrawn" do
      let(:editions) { [published_edition_v1, withdrawn_edition_v2] }

      it "returns true" do
        expect(section).to be_withdrawn
      end
    end

    context "one published and one withdrawn and one draft" do
      let(:editions) { [published_edition_v1, withdrawn_edition_v2, draft_edition_v3] }

      it "returns false" do
        expect(section).not_to be_withdrawn
      end
    end
  end

  describe "#withdraw_and_mark_as_exported!" do
    context "one draft" do
      let(:editions) { [draft_edition_v1] }

      it "archives the draft" do
        section.withdraw_and_mark_as_exported!

        expect(draft_edition_v1).to have_received(:archive)
      end

      it "sets the exported_at date on the draft" do
        time = Time.zone.now
        Timecop.freeze(time) do
          section.withdraw_and_mark_as_exported!
          expect(draft_edition_v1).to have_received(:exported_at=).with(time)
        end
      end
    end

    context "one published and one withdrawn" do
      let(:editions) { [published_edition_v1, withdrawn_edition_v2] }

      it "does nothing to the states of the editions" do
        section.withdraw_and_mark_as_exported!

        expect(published_edition_v1).not_to have_received(:archive)
        expect(withdrawn_edition_v2).not_to have_received(:archive)
      end

      it "only sets the exported_at date on the withdrawn edition" do
        time = Time.zone.now
        Timecop.freeze(time) do
          section.withdraw_and_mark_as_exported!
          expect(withdrawn_edition_v2).to have_received(:exported_at=).with(time)

          expect(published_edition_v1).not_to have_received(:exported_at=)
        end
      end
    end

    context "one published and one draft edition" do
      let(:editions) { [published_edition_v1, draft_edition_v2] }

      it "sets the draft edition's state to withdrawn" do
        section.withdraw_and_mark_as_exported!

        expect(draft_edition_v2).to have_received(:archive)
      end

      it "only sets the exported_at date on the draft edition" do
        time = Time.zone.now
        Timecop.freeze(time) do
          section.withdraw_and_mark_as_exported!
          expect(draft_edition_v2).to have_received(:exported_at=).with(time)

          expect(published_edition_v1).not_to have_received(:exported_at=)
        end
      end
    end

    context "one published edition" do
      let(:editions) { [published_edition_v1] }

      it "sets the published edition's state to withdrawn" do
        section.withdraw_and_mark_as_exported!

        expect(published_edition_v1).to have_received(:archive)
      end

      it "sets the exported_at date on the published edition" do
        time = Time.zone.now
        Timecop.freeze(time) do
          section.withdraw_and_mark_as_exported!
          expect(published_edition_v1).to have_received(:exported_at=).with(time)
        end
      end
    end
  end

  describe "#mark_as_exported!" do
    let(:editions) { [published_edition_v1, draft_edition_v2] }

    it "sets the exported_at date on the latest edition" do
      time = Time.zone.now
      Timecop.freeze(time) do
        section.mark_as_exported!
        expect(draft_edition_v2).to have_received(:exported_at=).with(time).ordered
        expect(draft_edition_v2).to have_received(:save).ordered

        expect(published_edition_v1).not_to have_received(:exported_at=)
        expect(published_edition_v1).not_to have_received(:save)
      end
    end
  end

  describe "#change_note_not_required?" do
    before do
      allow(section).to receive(:never_published?).and_return(never_published)
      allow(section).to receive(:minor_update?).and_return(minor_update)
    end

    context "when never published" do
      let(:never_published) { true }

      context "and update is minor" do
        let(:minor_update) { true }

        it "returns truthy" do
          expect(section.change_note_not_required?).to be_truthy
        end
      end

      context "and update is not minor" do
        let(:minor_update) { false }

        it "returns truthy" do
          expect(section.change_note_not_required?).to be_truthy
        end
      end
    end

    context "when has been published" do
      let(:never_published) { false }

      context "and update is minor" do
        let(:minor_update) { true }

        it "returns truthy" do
          expect(section.change_note_not_required?).to be_truthy
        end
      end

      context "and update is not minor" do
        let(:minor_update) { false }

        it "returns falsey" do
          expect(section.change_note_not_required?).to be_falsey
        end
      end
    end
  end

  describe "#change_note_provided?" do
    before do
      allow(section).to receive(:change_note).and_return(change_note)
    end

    context "when change note is present" do
      let(:change_note) { "Awesome update!" }

      it "returns truthy" do
        expect(section.change_note_provided?).to be_truthy
      end
    end

    context "when change note is not present" do
      let(:change_note) { nil }

      it "returns falsey" do
        expect(section.change_note_provided?).to be_falsey
      end
    end
  end
end
