require "spec_helper"

require "manual"

describe Manual do
  subject(:manual) do
    FactoryBot.build(
      :manual,
      id: id,
      slug: slug,
      title: title,
      summary: summary,
      body: body,
      organisation_slug: organisation_slug,
      state: state,
      updated_at: updated_at,
      version_number: 10,
      originally_published_at: originally_published_at,
      use_originally_published_at_for_public_timestamp: use_originally_published_at_for_public_timestamp,
    )
  end

  let(:id) { "0123-4567-89ab-cdef" }
  let(:updated_at) { Time.zone.parse("2001-01-01") }
  let(:originally_published_at) { Time.zone.parse("2002-02-02") }
  let(:use_originally_published_at_for_public_timestamp) { false }
  let(:title) { "manual-title" }
  let(:summary) { "manual-summary" }
  let(:body) { "manual-body" }
  let(:organisation_slug) { "organisation-slug" }
  let(:state) { "manual-state" }
  let(:slug) { "manual-slug" }

  it "generates an ID if none is provided" do
    manual = Manual.new
    expect(manual.id).to be_present
  end

  describe "#find_section" do
    it "returns the section if found" do
      manual = Manual.new
      section = manual.build_section({})

      found_manual = manual.find_section(section.uuid)
      expect(found_manual).to eql(section)
    end

    it "returns nil if the section can't be found" do
      manual = Manual.new

      found_manual = manual.find_section("made-up-uuid")
      expect(found_manual).to eql(nil)
    end
  end

  describe "#eql?" do
    it "is considered the same as another manual instance if they have the same id" do
      expect(manual).to eql(manual)
      expect(manual).to eql(FactoryBot.build(:manual, id: manual.id))
      expect(manual).not_to eql(FactoryBot.build(:manual, id: manual.id.reverse))
    end

    it "is considered the same as another manual instance with the same id even if the version number is different" do
      expect(manual).to eql(FactoryBot.build(:manual, id: manual.id, version_number: manual.version_number + 1))
    end
  end

  describe "#has_ever_been_published?" do
    it "is false if not told at initialize time" do
      expect(FactoryBot.build(:manual, id: "1234-5678-9012-3456")).not_to have_ever_been_published
    end

    it "is false if told so at initialize time" do
      expect(FactoryBot.build(:manual, id: "1234-5678-9012-3456", ever_been_published: false)).not_to have_ever_been_published
    end

    it "is true if told so at initialize time" do
      expect(FactoryBot.build(:manual, id: "1234-5678-9012-3456", ever_been_published: true)).to have_ever_been_published
    end
  end

  describe "#publish" do
    it "returns self" do
      expect(manual.publish).to be(manual)
    end

    let(:state) { "draft" }

    it "sets the state to 'published'" do
      manual.publish

      expect(manual.state).to eq("published")
    end

    context "when manual has sections" do
      let(:section1) { double(:section) }
      let(:section2) { double(:section) }

      before do
        allow(section1).to receive(:publish!)
        allow(section2).to receive(:publish!)
        manual.sections = [section1, section2]
      end

      it "calls publish! on each section" do
        manual.publish

        expect(section1).to have_received(:publish!)
        expect(section2).to have_received(:publish!)
      end
    end
  end

  describe "#version_number" do
    it "comes from the initializer attributes" do
      expect(manual.version_number).to eq 10
    end

    it "defaults to 0 if not supplied in the initalizer attributes" do
      expect(FactoryBot.build(:manual, id: "1234-5678").version_number).to eq 0
    end
  end

  describe "#publication_state" do
    context "for a manual in the draft state" do
      let(:state) { "draft" }

      it "is draft for the first edition" do
        allow(manual).to receive(:has_ever_been_published?).and_return false
        expect(manual.publication_state).to eql "draft"
      end

      it "is published if the manual has ever been published" do
        allow(manual).to receive(:has_ever_been_published?).and_return true
        expect(manual.publication_state).to eql "published"
      end
    end

    context "for a manual in the published state" do
      let(:state) { "published" }

      it "is published for the first edition" do
        allow(manual).to receive(:has_ever_been_published?).and_return false
        expect(manual.publication_state).to eql "published"
      end

      it "is published if the manual has ever been published" do
        allow(manual).to receive(:has_ever_been_published?).and_return true
        expect(manual.publication_state).to eql "published"
      end
    end

    context "for a manual in the withdrawn state" do
      let(:state) { "withdrawn" }

      it "is withdrawn for the first edition" do
        allow(manual).to receive(:has_ever_been_published?).and_return false
        expect(manual.publication_state).to eql "withdrawn"
      end

      it "is withdrawn if the manual has ever been published" do
        allow(manual).to receive(:has_ever_been_published?).and_return true
        expect(manual.publication_state).to eql "withdrawn"
      end
    end
  end

  describe "#update" do
    context "with allowed attirbutes" do
      let(:new_title) { "new-manual-title" }
      let(:new_summary) { "new-manual-summary" }
      let(:new_organisation_slug) { "new-organisation-slug" }
      let(:new_state) { "new-manual-state" }

      it "updates with the given attributes" do
        manual.assign_attributes(
          title: new_title,
          summary: new_summary,
          organisation_slug: new_organisation_slug,
          state: new_state,
        )

        expect(manual.title).to eq(new_title)
        expect(manual.summary).to eq(new_summary)
        expect(manual.organisation_slug).to eq(new_organisation_slug)
        expect(manual.state).to eq(new_state)
      end

      it "doesn't nil out attributes not in list" do
        manual.assign_attributes({})

        expect(manual.title).to eq(title)
        expect(manual.summary).to eq(summary)
        expect(manual.organisation_slug).to eq(organisation_slug)
        expect(manual.state).to eq(state)
      end
    end

    context "with disallowed attributes" do
      let(:new_id) { "new-manual-id" }
      let(:new_updated_at) { Time.zone.parse("2003-03-03") }

      it "does not update the attributes" do
        manual.assign_attributes(
          id: new_id,
          updated_at: new_updated_at,
        )

        expect(manual.id).to eq(id)
        expect(manual.updated_at).to eq(updated_at)
      end
    end
  end

  describe "#reorder_sections" do
    let(:sections) do
      [
        alpha_section,
        beta_section,
        gamma_section,
      ]
    end

    let(:alpha_section) { double(:section, uuid: "alpha") }
    let(:beta_section) { double(:section, uuid: "beta") }
    let(:gamma_section) { double(:section, uuid: "gamma") }

    let(:section_order) { %w[gamma alpha beta] }

    before do
      manual.sections = sections
    end

    it "reorders the sections to match the given order" do
      manual.reorder_sections(%w[
        gamma
        alpha
        beta
      ])

      expect(manual.sections.to_a).to eq([
        gamma_section,
        alpha_section,
        beta_section,
      ])
    end

    it "raises an error if section_order doesn't contain all IDs" do
      expect {
        manual.reorder_sections(%w[
          alpha
          beta
        ])
      }.to raise_error(ArgumentError)
    end

    it "raises an error if section_order contains non-existent IDs" do
      expect {
        manual.reorder_sections(%w[
          alpha
          beta
          gamma
          delta
        ])
      }.to raise_error(ArgumentError)
    end

    it "raises an error if section_order contains duplicate IDs" do
      expect {
        manual.reorder_sections(%w[
          alpha
          beta
          gamma
          beta
        ])
      }.to raise_error(ArgumentError)
    end
  end

  describe "#remove_section" do
    let(:sections) do
      [
        section_a,
        section_b,
      ]
    end
    let(:section_a) { double(:section, uuid: "a") }
    let(:section_b) { double(:section, uuid: "b") }

    let(:removed_sections) { [section_c] }
    let(:section_c) { double(:section, uuid: "c") }

    before do
      manual.sections = sections
      manual.removed_sections = removed_sections
    end

    it "removes the section from #sections" do
      manual.remove_section(section_a.uuid)

      expect(manual.sections.to_a).to eq([section_b])
    end

    it "adds the section to #removed_sections" do
      manual.remove_section(section_a.uuid)

      expect(manual.removed_sections.to_a).to eq(
        [
          section_c,
          section_a,
        ],
      )
    end
  end

  describe ".all" do
    let(:user) { FactoryBot.create(:gds_editor) }
    let!(:manual_records) do
      FactoryBot.create_list(:manual_record, 2, :with_sections, :with_removed_sections)
    end
    let(:all_manuals) { Manual.all(user) }

    it "evaluates lazily" do
      expect(all_manuals).to be_a_kind_of(Enumerator::Lazy)
    end

    it "returns all the manuals" do
      manual_ids = all_manuals.to_a.map(&:id)
      record_ids = manual_records.map(&:manual_id)

      expect(manual_ids).to match_array(record_ids)
    end

    it "adds associated sections to each manual" do
      all_manuals.each do |manual|
        expect(manual.sections).to_not be_empty
      end
    end

    it "adds associated removed sections to each manual" do
      all_manuals.each do |manual|
        expect(manual.removed_sections).to_not be_empty
      end
    end

    context "when requested not to load associations" do
      let(:all_manuals) { Manual.all(user, load_associations: false) }

      it "adds associated sections to each manual" do
        all_manuals.each do |manual|
          expect(manual.sections).to be_empty
        end
      end

      it "adds associated removed sections to each manual" do
        all_manuals.each do |manual|
          expect(manual.removed_sections).to be_empty
        end
      end
    end
  end

  describe ".find" do
    let(:user) { FactoryBot.create(:gds_editor) }

    context "when a manual record with the given id exists in the users collection" do
      let(:manual_record) { FactoryBot.create(:manual_record) }
      let(:edition) { manual_record.editions.first }

      it "builds and returns a manual from the manual record and its edition" do
        manual = Manual.find(manual_record.manual_id, user)

        expect(manual.id).to eq(manual_record.manual_id)
        expect(manual.slug).to eq(manual_record.slug)
        expect(manual.title).to eq(edition.title)
        expect(manual.summary).to eq(edition.summary)
        expect(manual.body).to eq(edition.body)
        expect(manual.organisation_slug).to eq(manual.organisation_slug)
        expect(manual.state).to eq(edition.state)
        expect(manual.version_number).to eq(edition.version_number)
        expect(manual.updated_at.to_i).to eq(edition.updated_at.to_i)
        expect(manual.originally_published_at.to_i).to eq(edition.originally_published_at.to_i)
        expect(manual.use_originally_published_at_for_public_timestamp).to eq(edition.use_originally_published_at_for_public_timestamp)
      end
    end

    context "when a manual record with the given id does not exist in the users collection" do
      it "raises a NotFoundError" do
        expect { Manual.find(1, user) }.to raise_error(Manual::NotFoundError)
      end
    end
  end

  describe "#save!" do
    let(:user) { FactoryBot.create(:gds_editor) }

    subject(:manual) do
      FactoryBot.build(
        :manual,
        id: "id",
        slug: "manual-slug",
        title: "title",
        summary: "summary",
        body: "body",
        organisation_slug: "organisation-slug",
        state: "state",
        updated_at: Time.zone.now,
        version_number: 1,
        originally_published_at: Time.zone.now,
        use_originally_published_at_for_public_timestamp: true,
      )
    end

    context "without sections or removed_sections" do
      it "sets the associated records slug" do
        manual.save!(user)

        record = ManualRecord.where(manual_id: manual.id).first
        expect(record.slug).to eq(manual.slug)
      end

      it "sets the associated records organisation slug" do
        manual.save!(user)

        record = ManualRecord.where(manual_id: manual.id).first
        expect(record.organisation_slug).to eq(manual.organisation_slug)
      end

      it "sets the properties of the associated edition" do
        manual.save!(user)

        record = ManualRecord.where(manual_id: manual.id).first
        edition = ManualRecord::Edition.where(
          manual_record_id: record.id,
        ).first

        expect(edition.title).to eq(manual.title)
        expect(edition.summary).to eq(manual.summary)
        expect(edition.body).to eq(manual.body)
        expect(edition.state).to eq(manual.state)
        # TODO: something better than `to_i` to compare times?
        expect(edition.originally_published_at.to_i).to eq(manual.originally_published_at.to_i)
        expect(edition.use_originally_published_at_for_public_timestamp).to eq(manual.use_originally_published_at_for_public_timestamp)
      end
    end

    context "with sections" do
      let(:section) { double(:section, uuid: "section-uuid", save!: nil) }

      before do
        manual.sections = [section]
      end

      it "tells the sections to save themselves" do
        expect(section).to receive(:save!)

        manual.save!(user)
      end

      it "associates the sections with the manual record edition" do
        manual.save!(user)

        record = ManualRecord.where(manual_id: manual.id).first
        edition = ManualRecord::Edition.where(
          manual_record_id: record.id,
        ).first

        expect(edition.section_uuids).to eq(%w[section-uuid])
      end
    end

    context "with removed sections" do
      let(:section) { double(:section, uuid: "section-uuid", save!: nil) }

      before do
        manual.removed_sections = [section]
      end

      it "tells the removed sections to save themselves" do
        expect(section).to receive(:save!)

        manual.save!(user)
      end

      it "associates the removed sections with the manual record edition" do
        manual.save!(user)

        record = ManualRecord.where(manual_id: manual.id).first
        edition = ManualRecord::Edition.where(
          manual_record_id: record.id,
        ).first

        expect(edition.removed_section_uuids).to eq(%w[section-uuid])
      end
    end
  end

  describe "#current_versions" do
    let(:manual) { Manual.find(manual_id, User.gds_editor) }

    context "when the provided id refers to the first draft of a manual" do
      let(:manual_id) { SecureRandom.uuid }
      let(:manual_record) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
      let(:manual_edition) { ManualRecord::Edition.new(section_uuids: %w[12345 67890], version_number: 1, state: "draft") }
      let!(:section1) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_uuid: "12345", version_number: 1, state: "draft") }
      let!(:section2) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_uuid: "67890", version_number: 1, state: "draft") }

      before do
        manual_record.editions << manual_edition
      end

      context "the published version returned" do
        it "is blank" do
          expect(manual.current_versions[:published]).to be_nil
        end
      end

      context "the draft version returned" do
        it "is the first draft as a Manual instance" do
          result = manual.current_versions[:draft]

          expect(result).to be_a ::Manual
          expect(result.id).to eq manual_id
          expect(result.state).to eq "draft"
          expect(result.version_number).to eq 1
          expect(result.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the first draft of the section editions as Section instances attached" do
          result = manual.current_versions[:draft]

          sections = result.sections.to_a
          expect(sections.size).to eq 2

          section1 = sections[0]
          expect(section1).to be_a ::Section
          expect(section1.uuid).to eq "12345"
          expect(section1).to be_draft
          expect(section1.version_number).to eq 1
          expect(section1.slug).to eq "guidance/my-amazing-manual/section-1"

          section2 = sections[1]
          expect(section2).to be_a ::Section
          expect(section2.uuid).to eq "67890"
          expect(section2).to be_draft
          expect(section2.version_number).to eq 1
          expect(section2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end
    end

    context "when the provided id refers to manual that has been published once" do
      let(:manual_id) { SecureRandom.uuid }
      let(:manual_record) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
      let(:manual_edition) { ManualRecord::Edition.new(section_uuids: %w[12345 67890], version_number: 1, state: "published") }
      let!(:section1) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_uuid: "12345", version_number: 1, state: "published") }
      let!(:section2) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_uuid: "67890", version_number: 1, state: "published") }

      before do
        manual_record.editions << manual_edition
      end

      context "the published version returned" do
        it "is the published version as a Manual instance" do
          result = manual.current_versions[:published]

          expect(result).to be_a ::Manual
          expect(result.id).to eq manual_id
          expect(result.state).to eq "published"
          expect(result.version_number).to eq 1
          expect(result.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the published version of the section editions as Section instances attached" do
          result = manual.current_versions[:published]

          sections = result.sections.to_a
          expect(sections.size).to eq 2

          section1 = sections[0]
          expect(section1).to be_a ::Section
          expect(section1.uuid).to eq "12345"
          expect(section1).to be_published
          expect(section1.version_number).to eq 1
          expect(section1.slug).to eq "guidance/my-amazing-manual/section-1"

          section2 = sections[1]
          expect(section2).to be_a ::Section
          expect(section2.uuid).to eq "67890"
          expect(section2).to be_published
          expect(section2.version_number).to eq 1
          expect(section2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end

      context "the draft version returned" do
        it "is blank" do
          expect(manual.current_versions[:draft]).to be_nil
        end
      end
    end

    context "when the provided id refers to manual that has been withdrawn once" do
      let(:manual_id) { SecureRandom.uuid }
      let(:manual_record) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
      let(:manual_edition) { ManualRecord::Edition.new(section_uuids: %w[12345 67890], version_number: 1, state: "withdrawn") }
      let!(:section1) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_uuid: "12345", version_number: 1, state: "archived") }
      let!(:section2) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_uuid: "67890", version_number: 1, state: "archived") }

      before do
        manual_record.editions << manual_edition
      end

      context "the published version returned" do
        it "is blank" do
          expect(manual.current_versions[:published]).to be_nil
        end
      end

      context "the draft version returned" do
        it "is blank" do
          expect(manual.current_versions[:draft]).to be_nil
        end
      end
    end

    context "when the provided id refers to manual that has been published once and has a new draft waiting" do
      let(:manual_id) { SecureRandom.uuid }
      let(:manual_record) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
      let(:manual_published_edition) { ManualRecord::Edition.new(section_uuids: %w[12345 67890], version_number: 1, state: "published") }
      let(:manual_draft_edition) { ManualRecord::Edition.new(section_uuids: %w[12345 67890], version_number: 2, state: "draft") }

      before do
        manual_record.editions << manual_published_edition
        manual_record.editions << manual_draft_edition
      end

      context "including new drafts of all sections" do
        let!(:section1_published) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_uuid: "12345", version_number: 1, state: "published") }
        let!(:section2_published) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_uuid: "67890", version_number: 1, state: "published") }
        let!(:section1_draft) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_uuid: "12345", version_number: 2, state: "draft") }
        let!(:section2_draft) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_uuid: "67890", version_number: 2, state: "draft") }

        context "the published version returned" do
          it "is the published version as a Manual instance" do
            result = manual.current_versions[:published]

            expect(result).to be_a ::Manual
            expect(result.id).to eq manual_id
            expect(result.state).to eq "published"
            expect(result.version_number).to eq 1
            expect(result.slug).to eq "guidance/my-amazing-manual"
          end

          it "has the published versions of the section editions as Section instances attached" do
            result = manual.current_versions[:published]

            sections = result.sections.to_a
            expect(sections.size).to eq 2

            section1 = sections[0]
            expect(section1).to be_a ::Section
            expect(section1.uuid).to eq "12345"
            expect(section1).to be_published
            expect(section1.version_number).to eq 1
            expect(section1.slug).to eq "guidance/my-amazing-manual/section-1"

            section2 = sections[1]
            expect(section2).to be_a ::Section
            expect(section2.uuid).to eq "67890"
            expect(section2).to be_published
            expect(section2.version_number).to eq 1
            expect(section2.slug).to eq "guidance/my-amazing-manual/section-2"
          end
        end

        context "the draft version returned" do
          it "is the new draft as a Manual instance" do
            result = manual.current_versions[:draft]

            expect(result).to be_a ::Manual
            expect(result.id).to eq manual_id
            expect(result.state).to eq "draft"
            expect(result.version_number).to eq 2
            expect(result.slug).to eq "guidance/my-amazing-manual"
          end

          it "has the new drafts of the section editions as Section instances attached" do
            result = manual.current_versions[:draft]

            sections = result.sections.to_a
            expect(sections.size).to eq 2

            section1 = sections[0]
            expect(section1).to be_a ::Section
            expect(section1.uuid).to eq "12345"
            expect(section1).to be_draft
            expect(section1.version_number).to eq 2
            expect(section1.slug).to eq "guidance/my-amazing-manual/section-1"

            section2 = sections[1]
            expect(section2).to be_a ::Section
            expect(section2.uuid).to eq "67890"
            expect(section2).to be_draft
            expect(section2.version_number).to eq 2
            expect(section2.slug).to eq "guidance/my-amazing-manual/section-2"
          end
        end
      end

      context "without new drafts of any sections" do
        let!(:section1_published) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_uuid: "12345", version_number: 1, state: "published") }
        let!(:section2_published) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_uuid: "67890", version_number: 1, state: "published") }

        context "the published version returned" do
          it "is the published version as a Manual instance" do
            result = manual.current_versions[:published]

            expect(result).to be_a ::Manual
            expect(result.id).to eq manual_id
            expect(result.state).to eq "published"
            expect(result.version_number).to eq 1
            expect(result.slug).to eq "guidance/my-amazing-manual"
          end

          it "has the published versions of the section editions as Section instances attached" do
            result = manual.current_versions[:published]

            sections = result.sections.to_a
            expect(sections.size).to eq 2

            section1 = sections[0]
            expect(section1).to be_a ::Section
            expect(section1.uuid).to eq "12345"
            expect(section1).to be_published
            expect(section1.version_number).to eq 1
            expect(section1.slug).to eq "guidance/my-amazing-manual/section-1"

            section2 = sections[1]
            expect(section2).to be_a ::Section
            expect(section2.uuid).to eq "67890"
            expect(section2).to be_published
            expect(section2.version_number).to eq 1
            expect(section2.slug).to eq "guidance/my-amazing-manual/section-2"
          end
        end

        context "the draft version returned" do
          it "is the new draft as a Manual instance" do
            result = manual.current_versions[:draft]

            expect(result).to be_a ::Manual
            expect(result.id).to eq manual_id
            expect(result.state).to eq "draft"
            expect(result.version_number).to eq 2
            expect(result.slug).to eq "guidance/my-amazing-manual"
          end

          it "has the published versions of the section editions as Section instances attached" do
            result = manual.current_versions[:published]

            sections = result.sections.to_a
            expect(sections.size).to eq 2

            section1 = sections[0]
            expect(section1).to be_a ::Section
            expect(section1.uuid).to eq "12345"
            expect(section1).to be_published
            expect(section1.version_number).to eq 1
            expect(section1.slug).to eq "guidance/my-amazing-manual/section-1"

            section2 = sections[1]
            expect(section2).to be_a ::Section
            expect(section2.uuid).to eq "67890"
            expect(section2).to be_published
            expect(section2.version_number).to eq 1
            expect(section2.slug).to eq "guidance/my-amazing-manual/section-2"
          end
        end
      end

      context "including new drafts of some sections" do
        let!(:section1_published) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-1", section_uuid: "12345", version_number: 1, state: "published") }
        let!(:section2_published) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_uuid: "67890", version_number: 1, state: "published") }
        let!(:section2_draft) { FactoryBot.create(:section_edition, slug: "#{manual_record.slug}/section-2", section_uuid: "67890", version_number: 2, state: "draft") }

        context "the published version returned" do
          it "is the published version as a Manual instance" do
            result = manual.current_versions[:published]

            expect(result).to be_a ::Manual
            expect(result.id).to eq manual_id
            expect(result.state).to eq "published"
            expect(result.version_number).to eq 1
            expect(result.slug).to eq "guidance/my-amazing-manual"
          end

          it "has the published versions of the section editions as Section instances attached" do
            result = manual.current_versions[:published]

            sections = result.sections.to_a
            expect(sections.size).to eq 2

            section1 = sections[0]
            expect(section1).to be_a ::Section
            expect(section1.uuid).to eq "12345"
            expect(section1).to be_published
            expect(section1.version_number).to eq 1
            expect(section1.slug).to eq "guidance/my-amazing-manual/section-1"

            section2 = sections[1]
            expect(section2).to be_a ::Section
            expect(section2.uuid).to eq "67890"
            expect(section2).to be_published
            expect(section2.version_number).to eq 1
            expect(section2.slug).to eq "guidance/my-amazing-manual/section-2"
          end
        end

        context "the draft version returned" do
          it "is the new draft as a Manual instance" do
            result = manual.current_versions[:draft]

            expect(result).to be_a ::Manual
            expect(result.id).to eq manual_id
            expect(result.state).to eq "draft"
            expect(result.version_number).to eq 2
            expect(result.slug).to eq "guidance/my-amazing-manual"
          end

          it "has correct draft or published version of the section editions as Section instances attached" do
            result = manual.current_versions[:draft]

            sections = result.sections.to_a
            expect(sections.size).to eq 2

            section1 = sections[0]
            expect(section1).to be_a ::Section
            expect(section1.uuid).to eq "12345"
            expect(section1).to be_published
            expect(section1.version_number).to eq 1
            expect(section1.slug).to eq "guidance/my-amazing-manual/section-1"

            section2 = sections[1]
            expect(section2).to be_a ::Section
            expect(section2.uuid).to eq "67890"
            expect(section2).to be_draft
            expect(section2.version_number).to eq 2
            expect(section2.slug).to eq "guidance/my-amazing-manual/section-2"
          end
        end
      end
    end
  end

  describe "#all_sections_are_minor?" do
    context "when manual has no sections" do
      before do
        allow(manual).to receive(:sections).and_return([])
      end

      it "returns truthy" do
        expect(manual.all_sections_are_minor?).to be_truthy
      end
    end

    context "when manual has sections" do
      let(:section1) { double(:section) }
      let(:section2) { double(:section) }
      let(:section3) { double(:section) }

      before do
        allow(manual).to receive(:sections).and_return([section1, section2, section3])
      end

      context "none of which need exporting" do
        before do
          allow(section1).to receive(:needs_exporting?).and_return(false)
          allow(section2).to receive(:needs_exporting?).and_return(false)
          allow(section3).to receive(:needs_exporting?).and_return(false)
        end

        it "returns truthy" do
          expect(manual.all_sections_are_minor?).to be_truthy
        end
      end

      context "some of which need exporting" do
        before do
          allow(section1).to receive(:needs_exporting?).and_return(false)
          allow(section2).to receive(:needs_exporting?).and_return(true)
          allow(section3).to receive(:needs_exporting?).and_return(true)
        end

        it "returns truthy when all those sections are minor versions" do
          allow(section1).to receive(:version_type).and_return(:major)
          allow(section2).to receive(:version_type).and_return(:minor)
          allow(section3).to receive(:version_type).and_return(:minor)

          expect(manual.all_sections_are_minor?).to be_truthy
        end

        it "returns falsey when at least one of those sections is a new version" do
          allow(section1).to receive(:version_type).and_return(:minor)
          allow(section2).to receive(:version_type).and_return(:minor)
          allow(section3).to receive(:version_type).and_return(:new)

          expect(manual.all_sections_are_minor?).to be_falsey
        end

        it "returns falsey when at least one of those sections is a major version" do
          allow(section1).to receive(:version_type).and_return(:minor)
          allow(section2).to receive(:version_type).and_return(:minor)
          allow(section3).to receive(:version_type).and_return(:major)

          expect(manual.all_sections_are_minor?).to be_falsey
        end
      end
    end
  end

  describe "#version_type" do
    context "when manual has never been published" do
      before do
        allow(manual).to receive(:has_ever_been_published?).and_return(false)
      end

      it "returns :new" do
        expect(manual.version_type).to eq(:new)
      end
    end

    context "when manual has been published before" do
      before do
        allow(manual).to receive(:has_ever_been_published?).and_return(true)
      end

      context "and all sections are minor" do
        before do
          allow(manual).to receive(:all_sections_are_minor?).and_return(true)
        end

        it "returns :minor" do
          expect(manual.version_type).to eq(:minor)
        end
      end

      context "and all sections are not minor" do
        before do
          allow(manual).to receive(:all_sections_are_minor?).and_return(false)
        end

        it "returns :major" do
          expect(manual.version_type).to eq(:major)
        end
      end
    end
  end

  describe "#publication_logs" do
    let(:publication_log) { PublicationLog.new }

    before do
      allow(PublicationLog).to receive(:change_notes_for).with(slug).and_return([publication_log])
    end

    it "returns change notes for manual" do
      expect(manual.publication_logs).to eq([publication_log])
    end
  end

  describe "#destroy" do
    let!(:manual_record) { FactoryBot.create(:manual_record, manual_id: manual.id) }

    it "destroys underlying manual record" do
      manual.destroy!

      expect(ManualRecord.find_by(id: manual_record.id)).not_to be_present
    end

    context "when manual has some sections with editions" do
      let(:section1_edition1) { FactoryBot.create(:section_edition, section_uuid: "section-1") }
      let(:section1_edition2) { FactoryBot.create(:section_edition, section_uuid: "section-1") }
      let(:section2_edition1) { FactoryBot.create(:section_edition, section_uuid: "section-2") }
      let(:section2_edition2) { FactoryBot.create(:section_edition, section_uuid: "section-2") }

      let(:section1) do
        Section.new(
          manual: manual,
          uuid: "section-1",
          previous_edition: section1_edition1,
          latest_edition: section1_edition2,
        )
      end

      let(:section2) do
        Section.new(
          manual: manual,
          uuid: "section-2",
          previous_edition: section2_edition1,
          latest_edition: section2_edition2,
        )
      end

      before do
        manual.sections = [section1, section2]
      end

      it "destroys all associated section editions" do
        manual.destroy!

        expect(SectionEdition.where(id: section1_edition1.id)).to be_empty
        expect(SectionEdition.where(id: section1_edition2.id)).to be_empty
        expect(SectionEdition.where(id: section2_edition1.id)).to be_empty
        expect(SectionEdition.where(id: section2_edition2.id)).to be_empty
      end
    end
  end

  describe ".find_by_slug!" do
    let(:user) { FactoryBot.create(:gds_editor) }

    context "when a manual record with the given slug exists" do
      let!(:manual_record) do
        FactoryBot.create(:manual_record, slug: "manual-slug")
      end

      it "builds and returns a manual from the manual record and its edition" do
        manual = Manual.find_by_slug!("manual-slug", user)
        expect(manual).to be_an_instance_of(Manual)
        expect(manual.id).to eq(manual_record.manual_id)
      end

      context "but user does not have access to manual record" do
        let(:user) { FactoryBot.create(:generic_editor_of_another_organisation) }

        it "raises Manual::NotFoundError" do
          expect {
            Manual.find_by_slug!("manual-slug", user)
          }.to raise_error(Manual::NotFoundError)
        end
      end
    end

    context "when a manual record with the given slug does not exist" do
      it "raises Manual::NotFoundError" do
        expect {
          Manual.find_by_slug!("manual-slug", user)
        }.to raise_error(Manual::NotFoundError)
      end
    end

    context "when multiple manual records with the given slug exist" do
      let!(:manual_record) do
        FactoryBot.create(:manual_record, slug: "manual-slug")
      end

      let!(:another_manual_record) do
        FactoryBot.create(:manual_record, slug: manual_record.slug)
      end

      it "raises Manual::AmbiguousSlugError" do
        expect {
          Manual.find_by_slug!("manual-slug", user)
        }.to raise_error(Manual::AmbiguousSlugError)
      end
    end
  end

  describe "#editions" do
    let!(:manual_record) { FactoryBot.create(:manual_record, manual_id: manual.id) }

    it "returns editions from underlying manual record" do
      expect(manual.editions).to eq(manual_record.editions)
    end
  end

  describe "#set" do
    let!(:manual_record) { FactoryBot.create(:manual_record, manual_id: manual.id) }

    it "sets attributes on underlying manual record" do
      manual.set(slug: "new-slug")
      expect(manual_record.reload.slug).to eq("new-slug")
    end
  end
end
