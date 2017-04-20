require "spec_helper"
require "section_reslugger"
require "section_slug_synchroniser"

RSpec.describe SectionSlugSynchroniser do
  let(:logger) { double(:logger) }

  subject { described_class.new("manual-slug", logger) }

  let(:manual_record) do
    ManualRecord.create!(
      manual_id: "manual-id",
      slug: "manual-slug",
      organisation_slug: "organisation-slug"
    )
  end

  before do
    section_ids = []

    4.times do |n|
      count = n + 1
      section_slug_number = 6 - n
      section_id = "section-id-#{count}"
      section_ids << section_id

      # A common use-case is number-prefixed section titles
      # which get out of sync with their slugs on reordering.
      SectionEdition.create!(
        section_id: section_id,
        slug: "manual-slug/#{section_slug_number}-section",
        title: "#{count}. Section",
        summary: "Section summary",
        body: "Section body"
      )
    end

    manual_record.editions.create!(
      section_ids: section_ids
    )
  end

  describe "report" do
    after { subject.report }

    it "logs changes to section slugs and potential conflicts" do
      expect(logger).to receive(:puts)
        .with("The following sections can be reslugged:")
      expect(logger).to receive(:puts)
        .with("'6-section' to '1-section'")
      expect(logger).to receive(:puts)
        .with("'5-section' to '2-section'")
      expect(logger).to receive(:puts)
        .with("The following sections cannot be reslugged:")
      expect(logger).to receive(:puts)
        .with("'4-section' would change to '3-section' but this is already in use.")
      expect(logger).to receive(:puts)
        .with("'3-section' would change to '4-section' but this is already in use.")
    end
  end

  describe "synchronise" do
    let(:reslugger) { double(:reslugger, call: nil) }

    it "calls SectionReslugger to reslug non-conflicting sections" do
      allow(logger).to receive(:puts).with(anything)

      expect(SectionReslugger).to receive(:new)
        .with("manual-slug", "6-section", "1-section")
        .and_return(reslugger)
      expect(SectionReslugger).to receive(:new)
        .with("manual-slug", "5-section", "2-section")
        .and_return(reslugger)

      subject.synchronise
    end
  end
end
