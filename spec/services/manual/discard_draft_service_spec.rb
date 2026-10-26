RSpec.describe Manual::DiscardDraftService do
  let(:manual_id) { double(:manual_id) }
  let(:manual) do
    double(
      :manual,
      id: manual_id,
      draft?: draft,
      has_ever_been_published?: has_ever_been_published,
      destroy!: nil,
      destroy_draft!: nil,
    )
  end
  let(:user) { double(:user) }

  subject do
    described_class.new(
      user:,
      manual_id:,
    )
  end

  before do
    allow(Manual).to receive(:find) { manual }
    allow(Publishing::DraftAdapter).to receive(:discard_draft_for_manual_and_sections)
  end

  context "when the manual has never been published" do
    let(:draft) { true }
    let(:has_ever_been_published) { false }

    it "returns a successful result" do
      result = subject.call
      expect(result).to be_successful
    end

    it "discards the manual via the publishing-api" do
      subject.call
      expect(Publishing::DraftAdapter).to have_received(:discard_draft_for_manual_and_sections).with(manual)
    end

    it "destroys the manual in the local db" do
      subject.call
      expect(manual).to have_received(:destroy!)
    end
  end

  context "when the manual has been published and has a new draft" do
    let(:draft) { true }
    let(:has_ever_been_published) { true }

    it "returns a successful result" do
      result = subject.call
      expect(result).to be_successful
    end

    it "discards the draft via the publishing-api" do
      subject.call
      expect(Publishing::DraftAdapter).to have_received(:discard_draft_for_manual_and_sections).with(manual)
    end

    it "discards only the draft in the local db" do
      subject.call
      expect(manual).to have_received(:destroy_draft!)
    end

    it "does not destroy the manual in the local db" do
      subject.call
      expect(manual).not_to have_received(:destroy!)
    end
  end

  context "when the manual has been published and has no draft" do
    let(:draft) { false }
    let(:has_ever_been_published) { true }

    it "returns a failure result" do
      result = subject.call
      expect(result).not_to be_successful
    end

    it "does not discard the manual via the publishing-api" do
      subject.call
      expect(Publishing::DraftAdapter).not_to have_received(:discard_draft_for_manual_and_sections).with(manual)
    end

    it "does not change the manual in the local db" do
      subject.call
      expect(manual).not_to have_received(:destroy!)
      expect(manual).not_to have_received(:destroy_draft!)
    end
  end
end
