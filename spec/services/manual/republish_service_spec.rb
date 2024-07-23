RSpec.describe Manual::RepublishService do
  let(:manual_id) { double(:manual_id) }
  let(:published_manual_version) { double(:manual) }
  let(:draft_manual_version) { double(:manual) }
  let(:manual) { double(:manual) }
  let(:user) { double(:user) }

  before do
    allow(Publishing::DraftAdapter).to receive(:save_draft_for_manual_and_sections)
    allow(PublishingAdapter).to receive(:publish_manual_and_sections)
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
      described_class.call(user:, manual_id:)
      expect(Publishing::DraftAdapter).to have_received(:save_draft_for_manual_and_sections).with(published_manual_version, republish: true)
    end

    it "calls the new publishing api publisher" do
      described_class.call(user:, manual_id:)
      expect(PublishingAdapter).to have_received(:publish_manual_and_sections).with(published_manual_version, republish: true)
    end

    it "tells the draft listeners nothing" do
      described_class.call(user:, manual_id:)
      expect(Publishing::DraftAdapter).not_to have_received(:save_draft_for_manual_and_sections).with(draft_manual_version, republish: true)
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
      described_class.call(user:, manual_id:)
      expect(PublishingAdapter).not_to have_received(:publish_manual_and_sections)
      expect(Publishing::DraftAdapter).not_to have_received(:save_draft_for_manual_and_sections).with(published_manual_version, republish: true)
    end

    it "tells the draft listeners to republish the draft version of the manual" do
      described_class.call(user:, manual_id:)
      expect(Publishing::DraftAdapter).to have_received(:save_draft_for_manual_and_sections).with(draft_manual_version, republish: true)
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
      described_class.call(user:, manual_id:)
      expect(Publishing::DraftAdapter).to have_received(:save_draft_for_manual_and_sections).with(published_manual_version, republish: true)
    end

    it "calls the new publishing api publisher" do
      described_class.call(user:, manual_id:)
      expect(PublishingAdapter).to have_received(:publish_manual_and_sections).with(published_manual_version, republish: true)
    end

    it "tells the draft listeners to republish the draft version of the manual" do
      described_class.call(user:, manual_id:)
      expect(Publishing::DraftAdapter).to have_received(:save_draft_for_manual_and_sections).with(draft_manual_version, republish: true)
    end
  end

  context "(for a manual that doesn't exist)" do
    let(:arbitrary_exception) { Class.new(StandardError) }

    before do
      allow(manual).to receive(:current_versions)
        .and_raise(arbitrary_exception)
    end

    it "tells none of the listeners to do anything" do
      expect { described_class.call(user:, manual_id:) }.to raise_error arbitrary_exception
      expect(Publishing::DraftAdapter).not_to have_received(:save_draft_for_manual_and_sections)
      expect(PublishingAdapter).not_to have_received(:publish_manual_and_sections)
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
      described_class.call(user:, manual_id:)
      expect(Publishing::DraftAdapter).not_to have_received(:save_draft_for_manual_and_sections)
      expect(PublishingAdapter).not_to have_received(:publish_manual_and_sections)
    end
  end
end
