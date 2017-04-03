require "spec_helper"

require "manual"

describe Manual do
  subject(:manual) {
    Manual.new(
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
  }

  let(:id) { "0123-4567-89ab-cdef" }
  let(:updated_at) { double(:updated_at) }
  let(:originally_published_at) { double(:originally_published_at) }
  let(:use_originally_published_at_for_public_timestamp) { double(:use_originally_published_at_for_public_timestamp) }
  let(:title) { double(:title) }
  let(:summary) { double(:summary) }
  let(:body) { double(:body) }
  let(:organisation_slug) { double(:organisation_slug) }
  let(:state) { double(:state) }
  let(:slug) { double(:slug) }

  it "rasies an error without an ID" do
    expect {
      Manual.new({})
    }.to raise_error(KeyError)
  end

  describe "#eql?" do
    it "is considered the same as another manual instance if they have the same id" do
      expect(manual).to eql(manual)
      expect(manual).to eql(Manual.new(id: manual.id))
      expect(manual).not_to eql(Manual.new(id: manual.id.reverse))
    end

    it "is considered the same as another manual instance with the same id even if the version number is different" do
      expect(manual).to eql(Manual.new(id: manual.id, version_number: manual.version_number + 1))
    end
  end

  describe "#has_ever_been_published?" do
    it "is false if not told at initialize time" do
      expect(Manual.new(id: "1234-5678-9012-3456")).not_to have_ever_been_published
    end

    it "is false if told so at initialize time" do
      expect(Manual.new(id: "1234-5678-9012-3456", ever_been_published: false)).not_to have_ever_been_published
    end

    it "is true if told so at initialize time" do
      expect(Manual.new(id: "1234-5678-9012-3456", ever_been_published: true)).to have_ever_been_published
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
      let(:section_1) { double(:section) }
      let(:section_2) { double(:section) }

      before do
        allow(section_1).to receive(:publish!)
        allow(section_2).to receive(:publish!)
        manual.sections = [section_1, section_2]
      end

      it "calls publish! on each section" do
        manual.publish

        expect(section_1).to have_received(:publish!)
        expect(section_2).to have_received(:publish!)
      end
    end
  end

  describe "#version_number" do
    it "comes from the initializer attributes" do
      expect(manual.version_number).to eq 10
    end

    it "defaults to 0 if not supplied in the initalizer attributes" do
      expect(Manual.new(id: "1234-5678").version_number).to eq 0
    end
  end

  describe "#attributes" do
    it "returns a hash of attributes" do
      expect(manual.attributes).to eq(
        id: id,
        title: title,
        slug: slug,
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
    it "returns self" do
      expect(manual.update({})).to be(manual)
    end

    context "with allowed attirbutes" do
      let(:new_title) { double(:new_title) }
      let(:new_summary) { double(:new_summary) }
      let(:new_organisation_slug) { double(:new_organisation_slug) }
      let(:new_state) { double(:new_state) }

      it "updates with the given attributes" do
        manual.update(
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
        manual.update({})

        expect(manual.title).to eq(title)
        expect(manual.summary).to eq(summary)
        expect(manual.organisation_slug).to eq(organisation_slug)
        expect(manual.state).to eq(state)
      end
    end

    context "with disallowed attributes" do
      let(:new_id) { double(:new_id) }
      let(:new_updated_at) { double(:new_updated_at) }

      it "does not update the attributes" do
        manual.update(
          id: new_id,
          updated_at: new_updated_at,
        )

        expect(manual.id).to eq(id)
        expect(manual.updated_at).to eq(updated_at)
      end
    end
  end

  describe "#reorder_sections" do
    let(:sections) {
      [
        alpha_section,
        beta_section,
        gamma_section,
      ]
    }

    let(:alpha_section) { double(:section, id: "alpha") }
    let(:beta_section) { double(:section, id: "beta") }
    let(:gamma_section) { double(:section, id: "gamma") }

    let(:section_order) { %w(gamma alpha beta) }

    before do
      manual.sections = sections
    end

    it "reorders the sections to match the given order" do
      manual.reorder_sections(%w(
        gamma
        alpha
        beta
      ))

      expect(manual.sections.to_a).to eq([
        gamma_section,
        alpha_section,
        beta_section,
      ])
    end

    it "raises an error if section_order doesn't contain all IDs" do
      expect {
        manual.reorder_sections(%w(
          alpha
          beta
        ))
      }.to raise_error(ArgumentError)
    end

    it "raises an error if section_order contains non-existent IDs" do
      expect {
        manual.reorder_sections(%w(
          alpha
          beta
          gamma
          delta
        ))
      }.to raise_error(ArgumentError)
    end

    it "raises an error if section_order contains duplicate IDs" do
      expect {
        manual.reorder_sections(%w(
          alpha
          beta
          gamma
          beta
        ))
      }.to raise_error(ArgumentError)
    end
  end

  describe "#remove_section" do
    let(:sections) {
      [
        section_a,
        section_b,
      ]
    }
    let(:section_a) { double(:section, id: "a") }
    let(:section_b) { double(:section, id: "b") }

    let(:removed_sections) { [section_c] }
    let(:section_c) { double(:section, id: "c") }

    before do
      manual.sections = sections
      manual.removed_sections = removed_sections
    end

    it "removes the section from #sections" do
      manual.remove_section(section_a.id)

      expect(manual.sections.to_a).to eq([section_b])
    end

    it "adds the section to #removed_sections" do
      manual.remove_section(section_a.id)

      expect(manual.removed_sections.to_a).to eq(
        [
          section_c,
          section_a,
        ]
      )
    end
  end
end
