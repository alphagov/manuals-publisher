require "spec_helper"

RSpec.describe Manual::RepublishService do
  let(:manual_id) { double(:manual_id) }
  let(:published_manual_version) { double(:manual) }
  let(:draft_manual_version) { double(:manual) }
  let(:publishing_adapter) { double(:publishing_adapter) }
  let(:search_index_adapter) { double(:search_index_adapter) }
  let(:manual) { double(:manual) }
  let(:user) { double(:user) }

  subject {
    described_class.new(
      user: user,
      manual_id: manual_id
    )
  }

  before do
    allow(Adapters).to receive(:publishing) { publishing_adapter }
    allow(Adapters).to receive(:search_index) { search_index_adapter }
    allow(publishing_adapter).to receive(:save)
    allow(publishing_adapter).to receive(:publish)
    allow(search_index_adapter).to receive(:add)
    allow(Manual).to receive(:find).with(manual_id, user) { manual }
  end

  context "(for a published manual)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: published_manual_version,
          draft: nil
        )
    end

    it "calls the publishing api draft exporter" do
      subject.call
      expect(publishing_adapter).to have_received(:save).with(published_manual_version, republish: true)
    end

    it "calls the new publishing api publisher" do
      subject.call
      expect(publishing_adapter).to have_received(:publish).with(published_manual_version, republish: true)
    end

    it "adds the manual to the search index" do
      subject.call
      expect(search_index_adapter).to have_received(:add).with(published_manual_version)
    end

    it "tells the draft listeners nothing" do
      subject.call
      expect(publishing_adapter).not_to have_received(:save).with(draft_manual_version, republish: true)
    end
  end

  context "(for a draft manual)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: nil,
          draft: draft_manual_version
        )
    end

    it "tells the published listeners nothing" do
      subject.call
      expect(publishing_adapter).not_to have_received(:publish)
      expect(publishing_adapter).not_to have_received(:save).with(published_manual_version, republish: true)
      expect(search_index_adapter).not_to have_received(:add)
    end

    it "tells the draft listeners to republish the draft version of the manual" do
      subject.call
      expect(publishing_adapter).to have_received(:save).with(draft_manual_version, republish: true)
    end
  end

  context "(for a published manual with a new draft waiting)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: published_manual_version,
          draft: draft_manual_version
        )
    end

    it "calls the publishing api draft exporter" do
      subject.call
      expect(publishing_adapter).to have_received(:save).with(published_manual_version, republish: true)
    end

    it "calls the new publishing api publisher" do
      subject.call
      expect(publishing_adapter).to have_received(:publish).with(published_manual_version, republish: true)
    end

    it "adds the manual to the search index" do
      subject.call
      expect(search_index_adapter).to have_received(:add).with(published_manual_version)
    end

    it "tells the draft listeners to republish the draft version of the manual" do
      subject.call
      expect(publishing_adapter).to have_received(:save).with(draft_manual_version, republish: true)
    end
  end

  context "(for a manual that doesn't exist)" do
    let(:arbitrary_exception) { Class.new(StandardError) }

    before do
      allow(manual).to receive(:current_versions)
        .and_raise(arbitrary_exception)
    end

    it "tells none of the listeners to do anything" do
      begin; subject.call; rescue(arbitrary_exception); end
      expect(publishing_adapter).not_to have_received(:save)
      expect(publishing_adapter).not_to have_received(:publish)
      expect(search_index_adapter).not_to have_received(:add)
    end
  end

  context "(for a manual that exists, but is neither published, nor draft)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: nil,
          draft: nil
        )
    end

    it "tells none of the listeners to do anything" do
      subject.call
      expect(publishing_adapter).not_to have_received(:save)
      expect(publishing_adapter).not_to have_received(:publish)
      expect(search_index_adapter).not_to have_received(:add)
    end
  end
end
