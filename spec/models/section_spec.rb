require "spec_helper"

describe Section do
  subject(:section) do
    Section.new(manual: manual, uuid: section_uuid, previous_edition: previous_edition, latest_edition: latest_edition)
  end

  def key_classes_for(hash)
    hash.keys.map(&:class).uniq
  end

  let(:manual_slug) { "/guidance/manual-slug" }
  let(:manual) { double(:manual, slug: manual_slug) }
  let(:section_uuid) { "a-section-uuid" }
  let(:slug) { double(:slug) }
  let(:published_slug) { double(:published_slug) }
  let(:slug_generator) { double(:slug_generator, call: slug) }
  let(:previous_edition) { nil }
  let(:latest_edition) { nil }
  let(:new_edition) { double(:new_edition, published?: false, draft?: true, assign_attributes: nil, version_number: 2) }
  let(:attachments) { double(:attachments) }

  let(:edition_messages) do
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
      save!: nil,
    }
  end

  let(:attachments_proxy) { double(:attachments_proxy, to_a: attachments) }

  let(:draft_edition_v1) do
    double(
      :draft_edition_v1,
      edition_messages.merge(
        title: "Draft edition v1",
        state: "draft",
        draft?: true,
        published?: false,
        archived?: false,
        version_number: 1,
        exported_at: nil,
      ),
    )
  end

  let(:draft_edition_v2) do
    double(
      :draft_edition_v2,
      edition_messages.merge(
        title: "Draft edition v2",
        state: "draft",
        draft?: true,
        published?: false,
        archived?: false,
        version_number: 2,
        exported_at: nil,
      ),
    )
  end

  let(:draft_edition_v3) do
    double(
      :draft_edition_v3,
      edition_messages.merge(
        title: "Draft edition v3",
        state: "draft",
        draft?: true,
        published?: false,
        archived?: false,
        version_number: 3,
        exported_at: nil,
      ),
    )
  end

  let(:published_edition_v1) do
    double(
      :published_edition_v1,
      edition_messages.merge(
        title: "Published edition",
        state: "published",
        published?: true,
        draft?: false,
        archived?: false,
        slug: published_slug,
        version_number: 1,
      ),
    )
  end

  let(:withdrawn_edition_v2) do
    double(
      :withdrawn_edition_v2,
      edition_messages.merge(
        title: "Withdrawn edition",
        state: "withdrawn",
        published?: false,
        draft?: false,
        archived?: true,
        slug: published_slug,
        version_number: 2,
      ),
    )
  end

  before do
    allow(SlugGenerator).to receive(:new).with(prefix: manual_slug).and_return(slug_generator)
  end

  describe "#update_slug!" do
    it "updates the slug of the section" do
      allow(SlugGenerator).to receive(:new).and_call_original

      manual = Manual.new(title: "manual-title")
      section = manual.build_section(title: "section-title")
      manual.save!(User.gds_editor)

      updated_slug = "guidance/manual-title/new-section-slug"
      section.update_slug!(updated_slug)

      expect(section.reload.slug).to eq(updated_slug)
    end
  end

  describe "#exported_at" do
    it "returns the date and time that the section was marked as exported" do
      exported_at = Time.zone.now
      subject.assign_attributes(title: "foo") # so the SectionEdtion is valid
      subject.mark_as_exported!(exported_at)
      expect(subject.exported_at).to eq(exported_at)
    end
  end

  describe "#reload" do
    let(:latest_edition) { draft_edition_v1 }

    it "reloads the latest edition of this section" do
      expect(draft_edition_v1).to receive(:reload)
      subject.reload
    end
  end

  describe ".find" do
    context "when there are associated section editions" do
      let(:previous_edition) { FactoryBot.build(:section_edition) }
      let(:latest_edition) { FactoryBot.build(:section_edition) }
      let(:editions_proxy) { double(:editions_proxy, to_a: [latest_edition, previous_edition]).as_null_object }

      before do
        allow(SectionEdition).to receive(:all_for_section).with("section-id").and_return(editions_proxy)
      end

      it "builds a section using the manual" do
        expect(Section).to receive(:new).with(including(manual: manual))
        Section.find(manual, "section-id")
      end

      it "builds a section using the section id" do
        expect(Section).to receive(:new).with(including(uuid: "section-id"))
        Section.find(manual, "section-id")
      end

      it "builds a section using the previous edition" do
        expect(Section).to receive(:new).with(including(previous_edition: previous_edition))
        Section.find(manual, "section-id")
      end

      it "builds a section using the latest edition" do
        expect(Section).to receive(:new).with(including(latest_edition: latest_edition))
        Section.find(manual, "section-id")
      end
    end

    context "when there aren't any associated section editions" do
      let(:editions_proxy) { double(:editions_proxy, to_a: []).as_null_object }

      before do
        allow(SectionEdition).to receive(:all_for_section).with("section-id").and_return(editions_proxy)
      end

      it "raises a key error exception" do
        expect { Section.find(manual, "section-id") }.to raise_error(KeyError)
      end
    end
  end

  describe "#save" do
    it "saves the previous and latest editions" do
      previous_edition = double(:previous_edition)
      latest_edition = double(:latest_edition)
      section = Section.new(manual: manual, uuid: "section-id", previous_edition: previous_edition, latest_edition: latest_edition)

      expect(previous_edition).to receive(:save!)
      expect(latest_edition).to receive(:save!)

      section.save!
    end
  end

  describe "#eql?" do
    let(:latest_edition) { draft_edition_v1 }

    it "is considered the same as another section instance if they have the same uuid" do
      expect(section).to eql(section)
      expect(section).to eql(Section.new(manual: manual, uuid: section.uuid, latest_edition: draft_edition_v1))
      expect(section).not_to eql(Section.new(manual: manual, uuid: section.uuid.reverse, latest_edition: draft_edition_v1))
    end

    it "is considered the same as another section instance with the same uuid even if they have different version numbers" do
      expect(section).to eql(Section.new(manual: manual, uuid: section.uuid, latest_edition: draft_edition_v2))
    end
  end

  context "with one draft edition" do
    let(:latest_edition) { draft_edition_v1 }

    it "is in draft" do
      expect(section).to be_draft
    end

    it "is not published" do
      expect(section).not_to be_published
    end
  end

  context "with one published edition" do
    let(:latest_edition) { published_edition_v1 }

    it "is published" do
      expect(section).to be_published
    end

    it "is not in draft" do
      expect(section).not_to be_draft
    end
  end

  context "with one published edition and one draft edition" do
    let(:previous_edition) { published_edition_v1 }
    let(:latest_edition) { draft_edition_v2 }

    it "is published and in draft" do
      expect(section).to be_draft
      expect(section).to be_published
    end
  end

  context "with two draft editions" do
    let(:previous_edition) { draft_edition_v1 }
    let(:latest_edition) { draft_edition_v2 }

    it "is in draft" do
      expect(section).to be_draft
    end

    it "is not published" do
      expect(section).not_to be_published
    end
  end

  context "with one draft edition and a withdrawn edition" do
    let(:previous_edition) { draft_edition_v1 }
    let(:latest_edition) { withdrawn_edition_v2 }

    it "is not in draft" do
      expect(section).not_to be_draft
    end

    it "is not published" do
      expect(section).not_to be_published
    end
  end

  describe "#update!" do
    context "section is new, with no previous editions" do
      let(:attrs)    { { title: "Test title" } }

      before do
        allow(SectionEdition).to receive(:new).and_return(new_edition)
      end

      it "creates the first edition" do
        section.assign_attributes(attrs)

        expect(SectionEdition).to have_received(:new).with(
          version_number: 1,
          state: "draft",
          section_uuid: section_uuid,
        )
      end
    end

    context "before the section is published" do
      context "with an existing draft edition" do
        let(:latest_edition) { draft_edition_v1 }

        context "when visually expanding" do
          it "recieves visually_expanded" do
            section.assign_attributes(visually_expanded: false)

            expect(draft_edition_v1).to have_received(:assign_attributes)
              .with(
                hash_including(
                  visually_expanded: false,
                ),
              )
          end
        end

        context "when providing a title" do
          let(:new_title) { double(:new_title) }
          let(:slug)      { double(:slug) }

          it "generates a slug" do
            section.assign_attributes(title: new_title)

            expect(slug_generator).to have_received(:call).with(new_title)
          end

          it "assigns the title and slug to the draft edition" do
            section.assign_attributes(title: new_title)

            expect(draft_edition_v1).to have_received(:assign_attributes)
              .with(
                hash_including(
                  title: new_title,
                  slug: slug,
                ),
              )
          end
        end
      end
    end

    context "when the current section is published" do
      let(:latest_edition) { published_edition_v1 }

      let(:attributes) { { title: "It is a new title" } }

      let(:edition_body) { double(:edition_body) }
      let(:edition_attributes) do
        {
          "_id" => "superfluous id",
          "updated_at" => "superfluous timestamp",
          "body" => edition_body,
          "arbitrary_attribute" => "arbitrary-attribute",
        }.with_indifferent_access
      end

      before do
        allow(published_edition_v1).to receive(:attributes)
          .and_return(edition_attributes)
        allow(SectionEdition).to receive(:new).and_return(new_edition)
      end

      it "builds a new edition with the new attributes" do
        section.assign_attributes(attributes)

        expect(SectionEdition).to have_received(:new).with(hash_including(attributes))
      end

      it "builds the new edition with attributes carried over from the previous edition" do
        section.assign_attributes(attributes)

        expect(SectionEdition).to have_received(:new)
          .with(hash_including(body: edition_body))
      end

      it "s attributes not defined as fields on the section edition" do
        section.assign_attributes(attributes)

        expect(SectionEdition).to_not have_received(:new)
          .with(hash_including(arbitrary_attribute: anything))
      end

      it "filters the previous edition's attributes" do
        section.assign_attributes(attributes)

        expect(SectionEdition).not_to have_received(:new)
          .with(
            hash_including(
              _id: "superfluous id",
              updated_at: "superfluous timestamp",
            ),
          )

        expect(SectionEdition).not_to have_received(:new)
          .with(
            hash_including(
              "_id" => "superfluous id",
              "updated_at" => "superfluous timestamp",
            ),
          )
      end

      it "builds a new edition with an incremented version number" do
        section.assign_attributes(attributes)

        expect(SectionEdition).to have_received(:new).with(hash_including(version_number: 2))
      end

      it "builds a new edition in the 'draft' state" do
        section.assign_attributes(attributes)

        expect(SectionEdition).to have_received(:new).with(hash_including(state: "draft"))
      end

      it "builds a new edition copying over the previous edition's attachments" do
        section.assign_attributes(attributes)

        expect(SectionEdition).to have_received(:new)
          .with(hash_including(attachments: attachments))
      end

      it "presents the new edition" do
        section.assign_attributes(attributes)

        expect(section.version_number).to eq(new_edition.version_number)
      end

      it "returns nil" do
        expect(section.assign_attributes(attributes)).to eq(nil)
      end

      context "when providing a title" do
        let(:new_title) { double(:new_title) }
        let(:slug)      { double(:slug) }

        before do
          allow(SectionEdition).to receive(:new).and_return(new_edition)
        end

        it "does not update the slug" do
          section.assign_attributes(title: new_title)

          expect(SectionEdition).to have_received(:new).with(
            hash_including(
              slug: published_slug,
            ),
          )
        end
      end
    end

    context "when the current section is withdrawn" do
      let(:latest_edition) { withdrawn_edition_v2 }

      let(:attributes) { { title: "It is a new title" } }

      before do
        allow(SectionEdition).to receive(:new).and_return(new_edition)
      end

      it "builds a new edition with the new attributes" do
        section.assign_attributes(attributes)

        expect(SectionEdition).to have_received(:new).with(hash_including(attributes))
      end

      it "builds a new edition with an incremented version number" do
        section.assign_attributes(attributes)

        expect(SectionEdition).to have_received(:new).with(hash_including(version_number: 3))
      end

      it "builds a new edition in the 'draft' state" do
        section.assign_attributes(attributes)

        expect(SectionEdition).to have_received(:new).with(hash_including(state: "draft"))
      end

      it "builds a new edition copying over the previous edition's attachments" do
        section.assign_attributes(attributes)

        expect(SectionEdition).to have_received(:new)
          .with(hash_including(attachments: attachments))
      end

      it "presents the new edition" do
        section.assign_attributes(attributes)

        expect(section.version_number).to eq(new_edition.version_number)
      end

      it "returns nil" do
        expect(section.assign_attributes(attributes)).to eq(nil)
      end

      context "when providing a title" do
        let(:new_title) { double(:new_title) }
        let(:slug)      { double(:slug) }

        it "does not update the slug" do
          section.assign_attributes(title: new_title)

          expect(SectionEdition).to have_received(:new).with(
            hash_including(
              slug: published_slug,
            ),
          )
        end
      end
    end
  end

  describe "#publish!" do
    context "one draft" do
      let(:latest_edition) { draft_edition_v1 }

      it "should set its state to published" do
        section.publish!
        expect(draft_edition_v1).to have_received(:publish)
      end
    end

    context "one published and one draft edition" do
      let(:previous_edition) { published_edition_v1 }
      let(:latest_edition) { draft_edition_v2 }

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
      let(:latest_edition) { published_edition_v1 }

      it "do nothing" do
        section.publish!
        expect(published_edition_v1).not_to have_received(:publish)
      end
    end
  end

  describe "#add_attachment" do
    let(:previous_edition) { published_edition_v1 }
    let(:latest_edition) { draft_edition_v2 }
    let(:attributes) { double(:attributes) }

    it "tells the latest edition to create an attachment using the supplied parameters" do
      section.add_attachment(attributes)

      expect(draft_edition_v2).to have_received(:build_attachment).with(attributes)
    end
  end

  describe "#attachments" do
    let(:previous_edition) { published_edition_v1 }
    let(:latest_edition) { draft_edition_v2 }

    it "delegates to the latest edition" do
      section.attachments

      expect(draft_edition_v2).to have_received(:attachments)
    end

    it "returns the attachments from the latest edition" do
      expect(section.attachments).to eq(attachments)
    end
  end

  describe "#find_attachment_by_id" do
    let(:latest_edition) { published_edition_v1 }

    let(:attachment_one) { double("attachment_one", id: id_object("one")) }
    let(:attachment_two) { double("attachment_two", id: id_object("two")) }

    let(:attachments) do
      [
        attachment_one,
        attachment_two,
      ]
    end

    def id_object(id_string)
      # like a Mongoid BSON id
      double(to_s: id_string)
    end

    it "returns the attachment with the corresponding id" do
      expect(
        section.find_attachment_by_id("one"),
      ).to eq(attachment_one)
    end

    it "returns nil if the attachment does not exist" do
      expect(
        section.find_attachment_by_id("does-not-exist"),
      ).to be_nil
    end
  end

  describe "#withdrawn?" do
    context "one draft" do
      let(:latest_edition) { draft_edition_v1 }

      it "returns false" do
        expect(section).not_to be_withdrawn
      end
    end

    context "one published" do
      let(:latest_edition) { published_edition_v1 }

      it "returns false" do
        expect(section).not_to be_withdrawn
      end
    end

    context "one published and one withdrawn" do
      let(:previous_edition) { published_edition_v1 }
      let(:latest_edition) { withdrawn_edition_v2 }

      it "returns true" do
        expect(section).to be_withdrawn
      end
    end

    context "one withdrawn and one draft" do
      let(:previous_edition) { withdrawn_edition_v2 }
      let(:latest_edition) { draft_edition_v3 }

      it "returns false" do
        expect(section).not_to be_withdrawn
      end
    end
  end

  describe "#withdraw_and_mark_as_exported!" do
    context "one draft" do
      let(:latest_edition) { draft_edition_v1 }

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
      let(:previous_edition) { published_edition_v1 }
      let(:latest_edition) { withdrawn_edition_v2 }

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
      let(:previous_edition) { published_edition_v1 }
      let(:latest_edition) { draft_edition_v2 }

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
      let(:latest_edition) { published_edition_v1 }

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
    let(:previous_edition) { published_edition_v1 }
    let(:latest_edition) { draft_edition_v2 }

    it "sets the exported_at date on the latest edition" do
      time = Time.zone.now
      Timecop.freeze(time) do
        section.mark_as_exported!
        expect(draft_edition_v2).to have_received(:exported_at=).with(time).ordered
        expect(draft_edition_v2).to have_received(:save!).ordered

        expect(published_edition_v1).not_to have_received(:exported_at=)
        expect(published_edition_v1).not_to have_received(:save!)
      end
    end
  end

  describe "#change_note_required?" do
    before do
      allow(section).to receive(:published?).and_return(published)
      allow(section).to receive(:minor_update?).and_return(minor_update)
    end

    context "when not published" do
      let(:published) { false }

      context "and update is minor" do
        let(:minor_update) { true }

        it "returns falsey" do
          expect(section.change_note_required?).to be_falsey
        end
      end

      context "and update is not minor" do
        let(:minor_update) { false }

        it "returns falsey" do
          expect(section.change_note_required?).to be_falsey
        end
      end
    end

    context "when has been published" do
      let(:published) { true }

      context "and update is minor" do
        let(:minor_update) { true }

        it "returns falsey" do
          expect(section.change_note_required?).to be_falsey
        end
      end

      context "and update is not minor" do
        let(:minor_update) { false }

        it "returns truthy" do
          expect(section.change_note_required?).to be_truthy
        end
      end
    end
  end

  describe "#valid?" do
    let(:latest_edition) { FactoryBot.build(:section_edition) }

    before do
      allow(section).to receive(:change_note_required?).and_return(change_note_required)
      allow(section).to receive(:change_note).and_return(change_note)
    end

    context "when change note not required" do
      let(:change_note_required) { false }

      context "and change note provided" do
        let(:change_note) { "Awesome update!" }

        it "is valid" do
          expect(section.valid?).to be_truthy
        end
      end

      context "and change note not provided" do
        let(:change_note) { "" }

        it "is valid" do
          expect(section.valid?).to be_truthy
        end
      end
    end

    context "when change note required" do
      let(:change_note_required) { true }

      context "and change note provided" do
        let(:change_note) { "Awesome update!" }

        it "is valid" do
          expect(section.valid?).to be_truthy
        end
      end

      context "and change note not provided" do
        let(:change_note) { "" }

        it "is not valid" do
          expect(section.valid?).to be_falsey
          expect(section.errors[:change_note]).to include("You must provide a change note or indicate minor update")
        end
      end
    end
  end

  describe "#first_edition?" do
    let(:manual) { Manual.new(title: "manual-title") }
    let(:section) { manual.build_section(title: "section-title") }

    before do
      allow(SlugGenerator).to receive(:new).and_call_original
    end

    it "returns true when the version_number is 1" do
      expect(section.version_number).to eq(1)
      expect(section).to be_first_edition
    end

    it "returns false when the version_number is greater than 1" do
      section.publish!
      section.save!
      section.assign_attributes(title: "new-section-title")

      expect(section.version_number).to eq(2)
      expect(section).to_not be_first_edition
    end
  end

  describe "#version_type" do
    context "when section is the first edition" do
      before do
        allow(section).to receive(:first_edition?).and_return(true)
      end

      it "returns :new" do
        expect(section.version_type).to eq(:new)
      end
    end

    context "when section is not the first edition" do
      before do
        allow(section).to receive(:first_edition?).and_return(false)
      end

      context "and update is minor" do
        before do
          allow(section).to receive(:minor_update?).and_return(true)
        end

        it "returns :minor" do
          expect(section.version_type).to eq(:minor)
        end
      end

      context "and update is major" do
        before do
          allow(section).to receive(:minor_update?).and_return(false)
        end

        it "returns :major" do
          expect(section.version_type).to eq(:major)
        end
      end
    end
  end

  describe "#all_editions" do
    let(:latest_edition) { FactoryBot.build(:section_edition) }

    before do
      allow(SectionEdition).to receive(:all_for_section).with(section_uuid).and_return([latest_edition])
    end

    it "returns all editions for section" do
      expect(section.all_editions).to eq([latest_edition])
    end
  end
end
