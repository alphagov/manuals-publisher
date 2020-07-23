require "spec_helper"

RSpec.describe Manual::RepublishService do
  let(:manual_id) { double(:manual_id) }
  let(:published_manual_version) { double(:manual) }
  let(:draft_manual_version) { double(:manual) }
  let(:publishing_adapter) { double(:publishing_adapter) }
  let(:manual) { double(:manual) }
  let(:user) { double(:user) }

  subject do
    described_class.new(
      user: user,
      manual_id: manual_id,
    )
  end

  before do
    allow(Adapters).to receive(:publishing) { publishing_adapter }
    allow(publishing_adapter).to receive(:save_draft)
    allow(publishing_adapter).to receive(:publish)
    allow(Manual).to receive(:find).with(manual_id, user) { manual }
  end

  context "(for a published manual)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: published_manual_version,
          draft: nil,
        )
    end

    it "calls the publishing api draft exporter" do
      subject.call
      expect(publishing_adapter).to have_received(:save_draft).with(published_manual_version, republish: true)
    end

    it "calls the new publishing api publisher" do
      subject.call
      expect(publishing_adapter).to have_received(:publish).with(published_manual_version, republish: true)
    end

    it "tells the draft listeners nothing" do
      subject.call
      expect(publishing_adapter).not_to have_received(:save_draft).with(draft_manual_version, republish: true)
    end
  end

  context "(for a draft manual)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: nil,
          draft: draft_manual_version,
        )
    end

    it "tells the published listeners nothing" do
      subject.call
      expect(publishing_adapter).not_to have_received(:publish)
      expect(publishing_adapter).not_to have_received(:save_draft).with(published_manual_version, republish: true)
    end

    it "tells the draft listeners to republish the draft version of the manual" do
      subject.call
      expect(publishing_adapter).to have_received(:save_draft).with(draft_manual_version, republish: true)
    end
  end

  context "(for a published manual with a new draft waiting)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: published_manual_version,
          draft: draft_manual_version,
        )
    end

    it "calls the publishing api draft exporter" do
      subject.call
      expect(publishing_adapter).to have_received(:save_draft).with(published_manual_version, republish: true)
    end

    it "calls the new publishing api publisher" do
      subject.call
      expect(publishing_adapter).to have_received(:publish).with(published_manual_version, republish: true)
    end

    it "tells the draft listeners to republish the draft version of the manual" do
      subject.call
      expect(publishing_adapter).to have_received(:save_draft).with(draft_manual_version, republish: true)
    end
  end

  context "(for a manual that doesn't exist)" do
    let(:arbitrary_exception) { Class.new(StandardError) }

    before do
      allow(manual).to receive(:current_versions)
        .and_raise(arbitrary_exception)
    end

    it "tells none of the listeners to do anything" do
      expect { subject.call }.to raise_error arbitrary_exception
      expect(publishing_adapter).not_to have_received(:save_draft)
      expect(publishing_adapter).not_to have_received(:publish)
    end
  end

  context "(for a manual that exists, but is neither published, nor draft)" do
    before do
      allow(manual).to receive(:current_versions)
        .and_return(
          published: nil,
          draft: nil,
        )
    end

    it "tells none of the listeners to do anything" do
      subject.call
      expect(publishing_adapter).not_to have_received(:save_draft)
      expect(publishing_adapter).not_to have_received(:publish)
    end
  end
end
