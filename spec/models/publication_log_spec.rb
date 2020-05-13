require "spec_helper"

describe PublicationLog, hits_db: true do
  describe "validation" do
    let(:attributes) do
      {
        slug: "my-slug",
        title: "my title",
        change_note: "First note",
        version_number: 1,
      }
    end

    subject(:publication_log) { PublicationLog.new(attributes) }

    context "all fields set" do
      it { should be_valid }
    end

    it "should be valid without a title" do
      publication_log.title = nil
      expect(publication_log).to be_valid
    end

    it "should be valid without a change_note" do
      publication_log.change_note = nil
      expect(publication_log).to be_valid
    end

    it "should be invalid without a slug" do
      publication_log.slug = nil
      expect(publication_log).not_to be_valid
    end

    it "should be invalid without a version_number" do
      publication_log.version_number = nil
      expect(publication_log).not_to be_valid
    end
  end

  describe ".change_notes_for" do
    context "there are some publication log entries" do
      let(:slug) { "guidance/my-slug" }
      let(:other_slug) { "not-guidance/another-one" }

      let!(:change_notes_for_first_doc) do
        [
          PublicationLog.create(
            slug: slug,
            title: "",
            change_note: "First note",
            version_number: 1,
            created_at: 10.seconds.ago,
          ),
          PublicationLog.create(
            slug: slug,
            title: "",
            change_note: "Second note",
            version_number: 2,
            created_at: 6.seconds.ago,
          ),
        ]
      end

      let!(:change_notes_for_second_doc) do
        [
          PublicationLog.create(
            slug: other_slug,
            title: "",
            change_note: "Another note",
            version_number: 1,
            created_at: 2.seconds.ago,
          ),
        ]
      end

      it "returns all the change notes for the given slug" do
        expect(PublicationLog.change_notes_for(slug)).to eq(change_notes_for_first_doc)
      end

      context "and some are for sections with similar slugs" do
        let!(:similar_slug) { "guidance/my-slug-belongs-to-me" }

        let!(:change_note_for_similar_slug) do
          PublicationLog.create(
            slug: similar_slug,
            title: "",
            change_note: "A similar note",
            version_number: 1,
          )
        end

        it "does not include the notes for the similar slug" do
          expect(PublicationLog.change_notes_for(slug)).not_to include change_note_for_similar_slug
        end
      end

      context "and some are for child sections of the slug" do
        let!(:child_slug) { "guidance/my-slug/my-lovely-section-slug" }

        let!(:change_note_for_child_slug) do
          PublicationLog.create(
            slug: child_slug,
            title: "",
            change_note: "A child note",
            version_number: 1,
          )
        end

        it "includes the notes for the child" do
          expect(PublicationLog.change_notes_for(slug)).to include change_note_for_child_slug
        end
      end

      context "multiple publication logs exist for a particular edition version" do
        before do
          PublicationLog.create(
            slug: slug,
            title: "",
            change_note: "Duplicate note",
            version_number: 2,
          )
        end

        it "removes duplicates" do
          expect(PublicationLog.change_notes_for(slug)).to eq(change_notes_for_first_doc)
        end
      end
    end

    context "no publication logs exist for a slug" do
      it "returns an empty list" do
        expect(PublicationLog.change_notes_for("guidance/my-slug")).to eq([])
      end
    end
  end
end
