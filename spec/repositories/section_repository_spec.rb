require "spec_helper"

describe SectionRepository do
  let(:section_repository) do
    SectionRepository.new(
      section_factory: section_factory,
    )
  end

  let(:section_factory) { double(:section_factory, call: section) }

  let(:section_id) { "section-id" }
  let(:section) {
    Section.new(slug_generator, section_id, editions, edition_factory)
  }

  let(:slug_generator) { double(:slug_generator) }

  let(:edition_factory) { double(:edition_factory) }
  let(:editions) { [new_draft_edition] }

  let(:new_draft_edition) {
    double(
      :new_draft_edition,
      title: "Example section about oil reserves",
      slug: "example-section-about-oil-reserves",
      "document_id=": nil,
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
      "document_id=": nil,
      changed?: false,
      save!: nil,
      archive: nil,
      published?: true,
      draft?: false,
      version_number: version,
    )
  end

  let(:published_edition) { build_published_edition }

  it "supports the fetch interface" do
    expect(section_repository).to be_a_kind_of(Fetchable)
  end

  describe "#all" do
    before do
      @edition_1, @edition_2 = [2, 1].map do |n|
        section_id = "section-id-#{n}"

        edition = FactoryGirl.create(:section_edition,
                                     document_id: section_id,
                                     updated_at: n.days.ago)

        allow(section_factory).to receive(:call)
          .with(section_id, [edition])
          .and_return(Section.new(slug_generator, section_id, [edition]))

        edition
      end
    end

    it "returns all sections by date updated desc" do
      expect(
        section_repository.all.map(&:title).to_a
      ).to eq([@edition_2, @edition_1].map(&:title))
    end
  end

  describe "#[]" do
    let(:editions_proxy) { double(:editions_proxy, to_a: editions).as_null_object }
    let(:editions)       { [published_edition] }

    before do
      allow(Section).to receive(:new).and_return(section)
      allow(SectionEdition).to receive(:all)
        .and_return(editions_proxy)
    end

    it "populates the section with all editions for that section id" do
      section_repository[section_id]

      expect(section_factory).to have_received(:call).with(section_id, editions)
    end

    it "returns the section" do
      expect(section_repository[section_id]).to eq(section)
    end

    context "when there are no editions" do
      before do
        allow(editions_proxy).to receive(:to_a).and_return([])
      end

      it "returns nil" do
        expect(section_repository[section_id]).to be_nil
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
