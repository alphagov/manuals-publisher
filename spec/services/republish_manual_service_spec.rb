require "fast_spec_helper"
require "republish_manual_service"

RSpec.describe RepublishManualService do
  let(:manual_id) { double(:manual_id) }
  let(:manual_repository) { double(:manual_repository) }
  let(:listener) { double(:listener) }
  let(:listeners) { [listener] }
  let(:manual) { double(:manual, id: manual_id, slug: "abc") }
  let(:tag_fetcher) { double(:tag_fetcher) }

  subject {
    RepublishManualService.new(
      manual_id: manual_id,
      manual_repository: manual_repository,
      listeners: listeners,
    )
  }

  before do
    allow(manual_repository).to receive(:fetch) { manual }
    allow(manual).to receive(:update)
    allow(listener).to receive(:call)
    allow(tag_fetcher).to receive(:tags).and_return(
      [
        OpenStruct.new(
          details: OpenStruct.new(
            type: "specialist_sector",
          ),
          slug: "government-digital-guidance/content-publishing",
        )
      ]
    )
    allow(TagFetcher).to receive(:new).and_return(tag_fetcher)
  end

  context "(for a published manual)" do
    before do
      allow(manual).to receive(:published?).and_return(true)
    end

    it "republishes the manual" do
      subject.call
      expect(listener).to have_received(:call).with(manual, :republish)
    end

    it "updates the manuals tags" do
      subject.call
      expect(manual).to have_received(:update).with(
        {
          tags: [
            {
              type: "specialist_sector",
              slug: "government-digital-guidance/content-publishing",
            }
          ]
        }
      ).at_least(1)
    end
  end

  context "(for a draft manual)" do
    before do
      allow(manual).to receive(:published?).and_return(false)
    end

    it "doesn't republish the manual" do
      subject.call
      expect(listener).to_not have_received(:call)
    end
  end
end
