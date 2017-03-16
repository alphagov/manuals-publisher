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

    it "yields to the block" do
      expect { |block|
        manual.publish(&block)
      }.to yield_with_no_args
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
end
