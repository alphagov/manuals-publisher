require "spec_helper"

require "manual_repository"

describe ManualRepository do
  subject(:repo) {
    ManualRepository.new(record_collection)
  }

  let(:record_collection) {
    double(:record_collection,
      find_or_initialize_by: nil,
    )
  }

  let(:manual_id) { double(:manual_id) }
  let(:manual_slug) { double(:manual_slug) }
  let(:originally_published_at) { double(:originally_published_at) }
  let(:use_originally_published_at_for_public_timestamp) { double(:use_originally_published_at_for_public_timestamp) }

  let(:manual) { double(:manual, manual_attributes) }

  let(:manual_attributes) {
    {
      id: manual_id,
      title: "title",
      state: "draft",
      summary: "summary",
      body: "body",
      organisation_slug: "organisation_slug",
      slug: manual_slug,
      ever_been_published: true,
      originally_published_at: originally_published_at,
      use_originally_published_at_for_public_timestamp: use_originally_published_at_for_public_timestamp,
    }
  }

  let(:manual_record) {
    double(
      :manual_record,
      manual_id: manual_id,
      new_or_existing_draft_edition: nil,
      organisation_slug: "organisation_slug",
      "organisation_slug=": nil,
      slug: manual_slug,
      "slug=": nil,
      latest_edition: nil,
      save!: nil,
      has_ever_been_published?: true,
    )
  }

  let(:edition) { double(:edition, edition_messages) }
  let(:edition_messages) {
    edition_attributes.merge(
      :attributes= => nil,
    )
  }
  let(:edition_attributes) {
    {
      title: "title",
      summary: "summary",
      body: "body",
      updated_at: "yesterday",
      organisation_slug: "organisation_slug",
      state: "draft",
      slug: manual_slug,
      version_number: 1,
      ever_been_published: true,
      originally_published_at: originally_published_at,
      use_originally_published_at_for_public_timestamp: use_originally_published_at_for_public_timestamp,
    }
  }

  it "supports the fetch interface" do
    expect(repo).to be_a_kind_of(Fetchable)
  end

  describe "#store" do
    let(:section_repository) {
      double(
        :section_repository,
        fetch: nil,
        store: nil,
      )
    }

    let(:section) { double(:section, id: 1) }
    let(:sections) { [section] }

    let(:removed_section) { double(:removed_section, id: 2) }
    let(:removed_sections) { [removed_section] }

    let(:draft_edition) { double(:draft_edition, :attributes= => nil) }

    before do
      allow(record_collection).to receive(:find_or_initialize_by)
        .and_return(manual_record)

      allow(SectionRepository).to receive(:new).with(manual: manual).and_return(section_repository)

      allow(manual_record).to receive(:new_or_existing_draft_edition)
        .and_return(edition)

      allow(manual).to receive(:sections).and_return(sections)
      allow(manual).to receive(:removed_sections).and_return(removed_sections)
      allow(edition).to receive(:'section_ids=')
      allow(edition).to receive(:'removed_section_ids=')
    end

    it "retrieves the manual record from the record collection" do
      repo.store(manual)

      expect(record_collection).to have_received(:find_or_initialize_by)
        .with(manual_id: manual_id)
    end

    it "retrieves a new or existing draft edition from the record" do
      repo.store(manual)

      expect(manual_record).to have_received(:new_or_existing_draft_edition)
    end

    it "updates the edition with the attributes from the object" do
      repo.store(manual)

      expect(edition).to have_received(:attributes=)
        .with(manual_attributes.slice(:title, :summary, :state, :body, :tags, :originally_published_at, :use_originally_published_at_for_public_timestamp))
    end

    it "sets the slug" do
      repo.store(manual)

      expect(manual_record).to have_received(:slug=).with(manual_slug)
    end

    it "sets the organisation_slug" do
      repo.store(manual)

      expect(manual_record).to have_received(:organisation_slug=).with("organisation_slug")
    end

    it "saves the manual" do
      repo.store(manual)

      expect(manual_record).to have_received(:save!)
    end

    it "saves associated sections and removed sections" do
      repo.store(manual)

      expect(section_repository).to have_received(:store).with(section)
      expect(section_repository).to have_received(:store).
        with(removed_section)
    end

    it "updates associated section ids on the edition" do
      repo.store(manual)

      expect(edition).to have_received(:section_ids=).with([section.id])
    end

    it "updates associated removed section ids on the edition" do
      repo.store(manual)

      expect(edition).to have_received(:removed_section_ids=).
        with([removed_section.id])
    end
  end

  describe "#[]" do
    let(:section_repository) { double(:section_repository) }

    before do
      allow(record_collection).to receive(:find_by).and_return(manual_record)
      allow(manual_record).to receive(:latest_edition).and_return(edition)
      allow(Manual).to receive(:new).and_return(manual)
      allow(SectionRepository).to receive(:new).with(manual: manual).and_return(section_repository)
      allow(manual).to receive(:'sections=')
      allow(manual).to receive(:'removed_sections=')
      allow(edition).to receive(:section_ids).and_return([:section_id])
      allow(edition).to receive(:removed_section_ids).and_return([:removed_section_id])
      allow(section_repository).to receive(:fetch).with(:section_id).and_return(:section)
      allow(section_repository).to receive(:fetch).with(:removed_section_id).and_return(:removed_section)
    end

    it "finds the manual record by manual id" do
      repo[manual_id]

      expect(record_collection).to have_received(:find_by)
        .with(manual_id: manual_id)
    end

    it "builds a new manual from the latest edition" do
      repo[manual_id]

      arguments = edition_attributes.merge(id: manual_id)

      expect(Manual).to have_received(:new)
        .with(arguments)
    end

    it 'adds the sections to the manual' do
      repo[manual_id]

      expect(manual).to have_received(:'sections=').with([:section])
    end

    it 'adds the removed sections to the manual' do
      repo[manual_id]

      expect(manual).to have_received(:'removed_sections=').with([:removed_section])
    end

    it "adds a publish task association to the manual" do
      expect(manual).to_not respond_to(:publish_tasks)

      manual = repo[manual_id]

      expect(manual).to respond_to(:publish_tasks)
    end
  end

  describe "#all" do
    before do
      allow(record_collection).to receive(:all_by_updated_at).and_return([manual_record])
      allow(manual_record).to receive(:latest_edition).and_return(edition)
      allow(Manual).to receive(:new).and_return(manual)
      allow(edition).to receive(:section_ids).and_return([])
      allow(edition).to receive(:removed_section_ids).and_return([])
      allow(manual).to receive(:'sections=')
      allow(manual).to receive(:'removed_sections=')
    end

    it "retrieves all records from the collection" do
      repo.all

      expect(record_collection).to have_received(:all_by_updated_at)
    end

    it "builds a manual for each record" do
      repo.all.to_a

      arguments = edition_attributes.merge(id: manual_id)

      expect(Manual).to have_received(:new).with(arguments)
    end

    it "builds lazily" do
      repo.all

      expect(Manual).not_to have_received(:new)
    end

    it "returns the built manuals" do
      allow(Manual).to receive(:new).and_return(manual)

      expect(repo.all.to_a).to eq([manual])
    end
  end
end
