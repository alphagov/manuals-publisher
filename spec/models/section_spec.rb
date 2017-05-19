require "spec_helper"

describe Section do
  subject(:section) {
    Section.new(manual: manual, uuid: section_uuid, editions: editions)
  }

  def key_classes_for(hash)
    hash.keys.map(&:class).uniq
  end

  let(:manual_slug) { '/guidance/manual-slug' }
  let(:manual) { double(:manual, slug: manual_slug) }
  let(:section_uuid) { "a-section-uuid" }
  let(:slug) { double(:slug) }
  let(:published_slug) { double(:published_slug) }
  let(:slug_generator) { double(:slug_generator, call: slug) }
  let(:editions) { [] }
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

  before do
    allow(SlugGenerator).to receive(:new).with(prefix: manual_slug).and_return(slug_generator)
  end

  describe '.find' do
    context 'when there are associated section editions' do
      let(:section_edition) { FactoryGirl.build(:section_edition) }
      let(:editions_proxy) { double(:editions_proxy, to_a: [section_edition]).as_null_object }

      before do
        allow(SectionEdition).to receive(:all_for_section).with('section-id').and_return(editions_proxy)
      end

      it 'builds a section using the manual' do
        expect(Section).to receive(:new).with(including(manual: manual))
        Section.find(manual, 'section-id')
      end

      it 'builds a section using the section id' do
        expect(Section).to receive(:new).with(including(uuid: 'section-id'))
        Section.find(manual, 'section-id')
      end

      it 'builds a section using the editions' do
        expect(Section).to receive(:new).with(including(editions: [section_edition]))
        Section.find(manual, 'section-id')
      end
    end

    context "when there aren't any associated section editions" do
      let(:editions_proxy) { double(:editions_proxy, to_a: []).as_null_object }

      before do
        allow(SectionEdition).to receive(:all_for_section).with('section-id').and_return(editions_proxy)
      end

      it 'raises a key error exception' do
        expect { Section.find(manual, 'section-id') }.to raise_error(KeyError)
      end
    end
  end

  describe '#save' do
    it 'saves the last two editions' do
      editions = [
        edition_1 = double(:edition_1),
        edition_2 = double(:edition_2),
        edition_3 = double(:edition_3)
      ]
      section = Section.new(manual: manual, uuid: 'section-id', editions: editions)

      expect(edition_1).to_not receive(:save!)
      expect(edition_2).to receive(:save!)
      expect(edition_3).to receive(:save!)

      section.save
    end
  end

  describe "#eql?" do
    let(:editions) { [draft_edition_v1] }

    it "is considered the same as another section instance if they have the same uuid" do
      expect(section).to eql(section)
      expect(section).to eql(Section.new(manual: manual, uuid: section.uuid, editions: [draft_edition_v1]))
      expect(section).not_to eql(Section.new(manual: manual, uuid: section.uuid.reverse, editions: [draft_edition_v1]))
    end

    it "is considered the same as another section instance with the same uuid even if they have different version numbers" do
      expect(section).to eql(Section.new(manual: manual, uuid: section.uuid, editions: [draft_edition_v2]))
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

      before do
        allow(SectionEdition).to receive(:new).and_return(new_edition)
      end

      it "creates the first edition" do
        section.update(attrs)

        expect(SectionEdition).to have_received(:new).with(
          version_number: 1,
          state: "draft",
          section_uuid: section_uuid,
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
          "arbitrary_attribute" => "arbitrary-attribute"
        }.with_indifferent_access
      }

      before do
        allow(published_edition_v1).to receive(:attributes)
          .and_return(edition_attributes)
        allow(SectionEdition).to receive(:new).and_return(new_edition)
      end

      it "builds a new edition with the new params" do
        section.update(params)

        expect(SectionEdition).to have_received(:new).with(hash_including(params))
      end

      it "builds the new edition with attributes carried over from the previous edition" do
        section.update(params)

        expect(SectionEdition).to have_received(:new)
          .with(hash_including(body: edition_body))
      end

      it "excludes attributes not defined as fields on the section edition" do
        section.update(params)

        expect(SectionEdition).to_not have_received(:new)
          .with(hash_including(arbitrary_attribute: anything))
      end

      it "filters the previous edition's attributes" do
        section.update(params)

        expect(SectionEdition).not_to have_received(:new)
          .with(
            hash_including(
              _id: "superfluous id",
              updated_at: "superfluous timestamp",
            )
          )

        expect(SectionEdition).not_to have_received(:new)
          .with(
            hash_including(
              "_id" => "superfluous id",
              "updated_at" => "superfluous timestamp",
            )
          )
      end

      it "builds a new edition with an incremented version number" do
        section.update(params)

        expect(SectionEdition).to have_received(:new).with(hash_including(version_number: 2))
      end

      it "builds a new edition in the 'draft' state" do
        section.update(params)

        expect(SectionEdition).to have_received(:new).with(hash_including(state: "draft"))
      end

      it "builds a new edition copying over the previous edition's attachments" do
        section.update(params)

        expect(SectionEdition).to have_received(:new)
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

        before do
          allow(SectionEdition).to receive(:new).and_return(new_edition)
        end

        it "does not update the slug" do
          section.update(title: new_title)

          expect(SectionEdition).to have_received(:new).with(
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

      before do
        allow(SectionEdition).to receive(:new).and_return(new_edition)
      end

      it "builds a new edition with the new params" do
        section.update(params)

        expect(SectionEdition).to have_received(:new).with(hash_including(params))
      end

      it "builds a new edition with an incremented version number" do
        section.update(params)

        expect(SectionEdition).to have_received(:new).with(hash_including(version_number: 3))
      end

      it "builds a new edition in the 'draft' state" do
        section.update(params)

        expect(SectionEdition).to have_received(:new).with(hash_including(state: "draft"))
      end

      it "builds a new edition copying over the previous edition's attachments" do
        section.update(params)

        expect(SectionEdition).to have_received(:new)
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

          expect(SectionEdition).to have_received(:new).with(
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
    let(:editions) { [FactoryGirl.build(:section_edition)] }

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

  describe "#version_type" do
    context "when section has never been published" do
      before do
        allow(section).to receive(:has_ever_been_published?).and_return(false)
      end

      it "returns :new" do
        expect(section.version_type).to eq(:new)
      end
    end

    context "when section has been published" do
      before do
        allow(section).to receive(:has_ever_been_published?).and_return(true)
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
    let(:editions) { [FactoryGirl.build(:section_edition)] }

    before do
      allow(SectionEdition).to receive(:all_for_section).with(section_uuid).and_return(editions)
    end

    it "returns all editions for section" do
      expect(section.all_editions).to eq(editions)
    end
  end
end
