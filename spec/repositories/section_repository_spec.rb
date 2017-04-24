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
end
