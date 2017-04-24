require "spec_helper"

describe SectionRepository do
  let(:section_repository) do
    SectionRepository.new
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
