require "spec_helper"

RSpec.describe VersionedManualRepository do
  subject(:repository) { described_class.new }

  context "when the provided id doesn't refer to a manual" do
    it "raises a Not Found error" do
      expect { subject.get_manual("i-dont-exist") }.to raise_error(ManualRepository::NotFoundError)
    end
  end

  context "when the provided id refers to the first draft of a manual" do
    let(:manual_id) { SecureRandom.uuid }
    let(:manual) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
    let(:manual_edition) { ManualRecord::Edition.new(document_ids: %w(12345 67890), version_number: 1, state: "draft") }
    let!(:section_1) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-1", document_id: "12345", version_number: 1, state: "draft") }
    let!(:section_2) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-2", document_id: "67890", version_number: 1, state: "draft") }
    before do
      manual.editions << manual_edition
    end

    context "the published version returned" do
      subject { repository.get_manual(manual_id)[:published] }

      it "is blank" do
        expect(subject).to be_nil
      end
    end

    context "the draft version returned" do
      subject { repository.get_manual(manual_id)[:draft] }

      it "is the first draft as a ManualWithDocuments instance" do
        expect(subject).to be_a ::ManualWithDocuments
        expect(subject.id).to eq manual_id
        expect(subject.state).to eq "draft"
        expect(subject.version_number).to eq 1
        expect(subject.slug).to eq "guidance/my-amazing-manual"
      end

      it "has the first draft of the section editions as Section instances attached" do
        documents = subject.documents.to_a
        expect(documents.size).to eq 2

        document_1 = documents[0]
        expect(document_1).to be_a ::Section
        expect(document_1.id).to eq "12345"
        expect(document_1).to be_draft
        expect(document_1.version_number).to eq 1
        expect(document_1.slug).to eq "guidance/my-amazing-manual/section-1"

        document_2 = documents[1]
        expect(document_2).to be_a ::Section
        expect(document_2.id).to eq "67890"
        expect(document_2).to be_draft
        expect(document_2.version_number).to eq 1
        expect(document_2.slug).to eq "guidance/my-amazing-manual/section-2"
      end
    end
  end

  context "when the provided id refers to manual that has been published once" do
    let(:manual_id) { SecureRandom.uuid }
    let(:manual) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
    let(:manual_edition) { ManualRecord::Edition.new(document_ids: %w(12345 67890), version_number: 1, state: "published") }
    let!(:section_1) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-1", document_id: "12345", version_number: 1, state: "published") }
    let!(:section_2) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-2", document_id: "67890", version_number: 1, state: "published") }
    before do
      manual.editions << manual_edition
    end

    context "the published version returned" do
      subject { repository.get_manual(manual_id)[:published] }

      it "is the published version as a ManualWithDocuments instance" do
        expect(subject).to be_a ::ManualWithDocuments
        expect(subject.id).to eq manual_id
        expect(subject.state).to eq "published"
        expect(subject.version_number).to eq 1
        expect(subject.slug).to eq "guidance/my-amazing-manual"
      end

      it "has the published version of the section editions as Section instances attached" do
        documents = subject.documents.to_a
        expect(documents.size).to eq 2

        document_1 = documents[0]
        expect(document_1).to be_a ::Section
        expect(document_1.id).to eq "12345"
        expect(document_1).to be_published
        expect(document_1.version_number).to eq 1
        expect(document_1.slug).to eq "guidance/my-amazing-manual/section-1"

        document_2 = documents[1]
        expect(document_2).to be_a ::Section
        expect(document_2.id).to eq "67890"
        expect(document_2).to be_published
        expect(document_2.version_number).to eq 1
        expect(document_2.slug).to eq "guidance/my-amazing-manual/section-2"
      end
    end

    context "the draft version returned" do
      subject { repository.get_manual(manual_id)[:draft] }

      it "is blank" do
        expect(subject).to be_nil
      end
    end
  end

  context "when the provided id refers to manual that has been withdrawn once" do
    let(:manual_id) { SecureRandom.uuid }
    let(:manual) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
    let(:manual_edition) { ManualRecord::Edition.new(document_ids: %w(12345 67890), version_number: 1, state: "withdrawn") }
    let!(:section_1) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-1", document_id: "12345", version_number: 1, state: "archived") }
    let!(:section_2) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-2", document_id: "67890", version_number: 1, state: "archived") }
    before do
      manual.editions << manual_edition
    end

    context "the published version returned" do
      subject { repository.get_manual(manual_id)[:published] }

      it "is blank" do
        expect(subject).to be_nil
      end
    end

    context "the draft version returned" do
      subject { repository.get_manual(manual_id)[:draft] }

      it "is blank" do
        expect(subject).to be_nil
      end
    end
  end

  context "when the provided id refers to manual that has been published once and has a new draft waiting" do
    let(:manual_id) { SecureRandom.uuid }
    let(:manual) { ManualRecord.create(manual_id: manual_id, slug: "guidance/my-amazing-manual", organisation_slug: "cabinet-office") }
    let(:manual_published_edition) { ManualRecord::Edition.new(document_ids: %w(12345 67890), version_number: 1, state: "published") }
    let(:manual_draft_edition) { ManualRecord::Edition.new(document_ids: %w(12345 67890), version_number: 2, state: "draft") }
    before do
      manual.editions << manual_published_edition
      manual.editions << manual_draft_edition
    end

    context "including new drafts of all sections" do
      let!(:section_1_published) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-1", document_id: "12345", version_number: 1, state: "published") }
      let!(:section_2_published) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-2", document_id: "67890", version_number: 1, state: "published") }
      let!(:section_1_draft) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-1", document_id: "12345", version_number: 2, state: "draft") }
      let!(:section_2_draft) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-2", document_id: "67890", version_number: 2, state: "draft") }

      context "the published version returned" do
        subject { repository.get_manual(manual_id)[:published] }

        it "is the published version as a ManualWithDocuments instance" do
          expect(subject).to be_a ::ManualWithDocuments
          expect(subject.id).to eq manual_id
          expect(subject.state).to eq "published"
          expect(subject.version_number).to eq 1
          expect(subject.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the published versions of the section editions as Section instances attached" do
          documents = subject.documents.to_a
          expect(documents.size).to eq 2

          document_1 = documents[0]
          expect(document_1).to be_a ::Section
          expect(document_1.id).to eq "12345"
          expect(document_1).to be_published
          expect(document_1.version_number).to eq 1
          expect(document_1.slug).to eq "guidance/my-amazing-manual/section-1"

          document_2 = documents[1]
          expect(document_2).to be_a ::Section
          expect(document_2.id).to eq "67890"
          expect(document_2).to be_published
          expect(document_2.version_number).to eq 1
          expect(document_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end

      context "the draft version returned" do
        subject { repository.get_manual(manual_id)[:draft] }

        it "is the new draft as a ManualWithDocuments instance" do
          expect(subject).to be_a ::ManualWithDocuments
          expect(subject.id).to eq manual_id
          expect(subject.state).to eq "draft"
          expect(subject.version_number).to eq 2
          expect(subject.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the new drafts of the section editions as Section instances attached" do
          documents = subject.documents.to_a
          expect(documents.size).to eq 2

          document_1 = documents[0]
          expect(document_1).to be_a ::Section
          expect(document_1.id).to eq "12345"
          expect(document_1).to be_draft
          expect(document_1.version_number).to eq 2
          expect(document_1.slug).to eq "guidance/my-amazing-manual/section-1"

          document_2 = documents[1]
          expect(document_2).to be_a ::Section
          expect(document_2.id).to eq "67890"
          expect(document_2).to be_draft
          expect(document_2.version_number).to eq 2
          expect(document_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end
    end

    context "without new drafts of any sections" do
      let!(:section_1_published) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-1", document_id: "12345", version_number: 1, state: "published") }
      let!(:section_2_published) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-2", document_id: "67890", version_number: 1, state: "published") }

      context "the published version returned" do
        subject { repository.get_manual(manual_id)[:published] }

        it "is the published version as a ManualWithDocuments instance" do
          expect(subject).to be_a ::ManualWithDocuments
          expect(subject.id).to eq manual_id
          expect(subject.state).to eq "published"
          expect(subject.version_number).to eq 1
          expect(subject.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the published versions of the section editions as Section instances attached" do
          documents = subject.documents.to_a
          expect(documents.size).to eq 2

          document_1 = documents[0]
          expect(document_1).to be_a ::Section
          expect(document_1.id).to eq "12345"
          expect(document_1).to be_published
          expect(document_1.version_number).to eq 1
          expect(document_1.slug).to eq "guidance/my-amazing-manual/section-1"

          document_2 = documents[1]
          expect(document_2).to be_a ::Section
          expect(document_2.id).to eq "67890"
          expect(document_2).to be_published
          expect(document_2.version_number).to eq 1
          expect(document_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end

      context "the draft version returned" do
        subject { repository.get_manual(manual_id)[:draft] }

        it "is the new draft as a ManualWithDocuments instance" do
          expect(subject).to be_a ::ManualWithDocuments
          expect(subject.id).to eq manual_id
          expect(subject.state).to eq "draft"
          expect(subject.version_number).to eq 2
          expect(subject.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the published versions of the section editions as Section instances attached" do
          documents = subject.documents.to_a
          expect(documents.size).to eq 2

          document_1 = documents[0]
          expect(document_1).to be_a ::Section
          expect(document_1.id).to eq "12345"
          expect(document_1).to be_published
          expect(document_1.version_number).to eq 1
          expect(document_1.slug).to eq "guidance/my-amazing-manual/section-1"

          document_2 = documents[1]
          expect(document_2).to be_a ::Section
          expect(document_2.id).to eq "67890"
          expect(document_2).to be_published
          expect(document_2.version_number).to eq 1
          expect(document_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end
    end

    context "including new drafts of some sections" do
      let!(:section_1_published) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-1", document_id: "12345", version_number: 1, state: "published") }
      let!(:section_2_published) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-2", document_id: "67890", version_number: 1, state: "published") }
      let!(:section_2_draft) { FactoryGirl.create(:specialist_document_edition, slug: "#{manual.slug}/section-2", document_id: "67890", version_number: 2, state: "draft") }

      context "the published version returned" do
        subject { repository.get_manual(manual_id)[:published] }

        it "is the published version as a ManualWithDocuments instance" do
          expect(subject).to be_a ::ManualWithDocuments
          expect(subject.id).to eq manual_id
          expect(subject.state).to eq "published"
          expect(subject.version_number).to eq 1
          expect(subject.slug).to eq "guidance/my-amazing-manual"
        end

        it "has the published versions of the section editions as Section instances attached" do
          documents = subject.documents.to_a
          expect(documents.size).to eq 2

          document_1 = documents[0]
          expect(document_1).to be_a ::Section
          expect(document_1.id).to eq "12345"
          expect(document_1).to be_published
          expect(document_1.version_number).to eq 1
          expect(document_1.slug).to eq "guidance/my-amazing-manual/section-1"

          document_2 = documents[1]
          expect(document_2).to be_a ::Section
          expect(document_2.id).to eq "67890"
          expect(document_2).to be_published
          expect(document_2.version_number).to eq 1
          expect(document_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end

      context "the draft version returned" do
        subject { repository.get_manual(manual_id)[:draft] }

        it "is the new draft as a ManualWithDocuments instance" do
          expect(subject).to be_a ::ManualWithDocuments
          expect(subject.id).to eq manual_id
          expect(subject.state).to eq "draft"
          expect(subject.version_number).to eq 2
          expect(subject.slug).to eq "guidance/my-amazing-manual"
        end

        it "has correct draft or published version of the section editions as Section instances attached" do
          documents = subject.documents.to_a
          expect(documents.size).to eq 2

          document_1 = documents[0]
          expect(document_1).to be_a ::Section
          expect(document_1.id).to eq "12345"
          expect(document_1).to be_published
          expect(document_1.version_number).to eq 1
          expect(document_1.slug).to eq "guidance/my-amazing-manual/section-1"

          document_2 = documents[1]
          expect(document_2).to be_a ::Section
          expect(document_2.id).to eq "67890"
          expect(document_2).to be_draft
          expect(document_2.version_number).to eq 2
          expect(document_2.slug).to eq "guidance/my-amazing-manual/section-2"
        end
      end
    end
  end
end
