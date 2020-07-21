require "spec_helper"

describe MarkedSectionDeleter do
  subject do
    described_class.new(StringIO.new)
  end

  let(:publishing_api) { double(:publishing_api) }

  before do
    allow(Services).to receive(:publishing_api).and_return(publishing_api)
  end

  context "when edition is marked for deletion but isn't in publishing api" do
    let!(:edition) do
      FactoryBot.create(:section_edition, title: "xx-to-be-deleted")
    end

    before do
      allow(publishing_api)
        .to receive(:get_content)
        .with(edition.section_uuid)
        .and_raise(GdsApi::HTTPNotFound.new(nil))
    end

    it "deletes the edition" do
      subject.execute(dry_run: false)

      expect(SectionEdition.count).to eql(0)
    end
  end

  context "when edition is marked for deletion and is in publishing api" do
    let!(:edition) do
      FactoryBot.create(:section_edition, title: "xx-to-be-deleted")
    end

    before do
      allow(publishing_api)
        .to receive(:get_content)
        .with(edition.section_uuid)
        .and_return(double(:gds_api_response))
      allow(publishing_api)
        .to receive(:discard_draft)
        .with(edition.section_uuid)
    end

    it "deletes the edition" do
      subject.execute(dry_run: false)

      expect(SectionEdition.count).to eql(0)
    end

    it "discards the draft from the publishing api" do
      expect(publishing_api)
        .to receive(:discard_draft)
        .with(edition.section_uuid)

      subject.execute(dry_run: false)
    end
  end

  context "when edition isn't marked for deletion" do
    let!(:edition) do
      FactoryBot.create(:section_edition, title: "not-to-be-deleted")
    end

    it "doesn't delete any editions" do
      subject.execute(dry_run: false)

      expect(SectionEdition.count).to eql(1)
    end
  end

  context "when executed in dry run mode" do
    let!(:edition) do
      FactoryBot.create(:section_edition, title: "xx-to-be-deleted")
    end

    before do
      allow(publishing_api).to receive(:get_content)
    end

    it "doesn't delete any editions" do
      subject.execute(dry_run: true)

      expect(SectionEdition.count).to eql(1)
    end

    it "doesn't discard any drafts from the publishing api" do
      expect(publishing_api).to_not receive(:discard_draft)

      subject.execute(dry_run: true)
    end
  end
end
