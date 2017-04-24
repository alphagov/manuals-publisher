require "spec_helper"

describe SectionRepository do
  let(:section_repository) do
    SectionRepository.new(
      manual: manual,
    )
  end

  let(:manual) { double(:manual) }

  let(:section_id) { "section-id" }
  let(:section) {
    Section.new(slug_generator, section_id, editions)
  }

  let(:slug_generator) { double(:slug_generator) }

  let(:editions) { [new_draft_edition] }

  let(:new_draft_edition) {
    double(
      :new_draft_edition,
      title: "Example section about oil reserves",
      slug: "example-section-about-oil-reserves",
      "section_id=": nil,
      "slug=": nil,
      changed?: true,
      save!: true,
      published?: false,
      draft?: true,
      errors: {},
      publish: nil,
      version_number: 2,
      archive: nil,
    )
  }

  def build_published_edition(version: 1)
    double(
      :published_edition,
      title: "Example section about oil reserves #{version}",
      "section_id=": nil,
      changed?: false,
      save!: nil,
      archive: nil,
      published?: true,
      draft?: false,
      version_number: version,
    )
  end

  let(:published_edition) { build_published_edition }

  before do
    allow(Section).to receive(:build)
      .with(manual: manual, id: section_id, editions: [published_edition])
      .and_return(section)
  end

  describe "#fetch" do
    let(:editions_proxy) { double(:editions_proxy, to_a: editions).as_null_object }
    let(:editions)       { [published_edition] }

    before do
      allow(Section).to receive(:new).and_return(section)
      allow(SectionEdition).to receive(:two_latest_versions)
        .and_return(editions_proxy)
    end

    it "populates the section with all editions for that section id" do
      section_repository.fetch(section_id)

      expect(Section).to have_received(:build)
        .with(manual: manual, id: section_id, editions: editions)
    end

    it "returns the section" do
      expect(section_repository.fetch(section_id)).to eq(section)
    end

    context "when there are no editions" do
      before do
        allow(editions_proxy).to receive(:to_a).and_return([])
      end

      it "raises a key error" do
        expect { section_repository.fetch(section_id) }.to raise_error(KeyError)
      end
    end
  end

  describe "#store(section)" do
    context "with a valid editions" do
      let(:previous_edition) { build_published_edition(version: 1) }
      let(:current_published_edition) { build_published_edition(version: 2) }

      let(:editions) {
        [
          previous_edition,
          current_published_edition,
          new_draft_edition,
        ]
      }

      it "returns self" do
        expect(section_repository.store(section)).to be(
          section_repository
        )
      end

      it "saves the the two most recent editions" do
        section_repository.store(section)

        expect(new_draft_edition).to have_received(:save!)
        expect(current_published_edition).to have_received(:save!)
        expect(previous_edition).not_to have_received(:save!)
      end
    end
  end
end
