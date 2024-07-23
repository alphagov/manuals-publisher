require "ostruct"

RSpec.describe Manual::PublishService do
  let(:manual_id) { double(:manual_id) }
  let(:manual) { double(:manual, id: manual_id, version_number: 3) }
  let(:publication_logger) { double(:publication_logger) }
  let(:user) { double(:user) }

  subject do
    Manual::PublishService.new(
      user:,
      manual_id:,
      version_number:,
    )
  end

  before do
    allow(Manual).to receive(:find) { manual }
    allow(manual).to receive(:save!)
    allow(manual).to receive(:publish)
    allow(PublicationLogger).to receive(:new) { publication_logger }
    allow(publication_logger).to receive(:call)
    allow(Publishing::DraftAdapter).to receive(:save_draft_for_manual_and_sections)
    allow(PublishingAdapter).to receive(:publish_manual_and_sections)
  end

  context "when the version number is up to date" do
    let(:version_number) { 3 }

    it "publishes the manual" do
      subject.call
      expect(manual).to have_received(:publish)
    end

    it "calls the publication logger" do
      subject.call
      expect(publication_logger).to have_received(:call).with(manual)
    end

    it "calls the publishing api draft exporter" do
      subject.call
      expect(Publishing::DraftAdapter).to have_received(:save_draft_for_manual_and_sections).with(manual)
    end

    it "calls the new publishing api publisher" do
      subject.call
      expect(PublishingAdapter).to have_received(:publish_manual_and_sections).with(manual)
    end

    it "makes the calls to the collaborators in the correct order" do
      subject.call

      expect(publication_logger).to have_received(:call).ordered
      expect(Publishing::DraftAdapter).to have_received(:save_draft_for_manual_and_sections).ordered
      expect(PublishingAdapter).to have_received(:publish_manual_and_sections).ordered
    end
  end

  context "when the version numbers differ" do
    let(:version_number) { 4 }

    it "should raise a Manual::PublishService::VersionMismatchError" do
      expect { subject.call }.to raise_error(Manual::PublishService::VersionMismatchError)
    end
  end
end
