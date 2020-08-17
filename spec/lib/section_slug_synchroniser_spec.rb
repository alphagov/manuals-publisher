require "spec_helper"

RSpec.describe SectionSlugSynchroniser do
  let(:logger) { double(:logger) }

  subject { described_class.new("manual-slug", logger) }

  let(:manual_record) do
    ManualRecord.create!(
      manual_id: "manual-id",
      slug: "manual-slug",
      organisation_slug: "organisation-slug",
    )
  end

  context "when sections are out of sync" do
    before do
      section_uuids = []

      4.times do |n|
        count = n + 1
        section_slug_number = 6 - n
        section_uuid = "section-uuid-#{count}"
        section_uuids << section_uuid

        # A common use-case is number-prefixed section titles
        # which get out of sync with their slugs on reordering.
        SectionEdition.create!(
          section_uuid: section_uuid,
          slug: "manual-slug/#{section_slug_number}-section",
          title: "#{count}. Section",
          summary: "Section summary",
          body: "Section body",
        )
      end

      manual_record.editions.create!(
        section_uuids: section_uuids,
      )
    end

    describe "report" do
      after { subject.report }

      it "logs changes to section slugs and potential conflicts" do
        expect(logger).to receive(:puts)
          .with("The following sections can be reslugged:")
        expect(logger).to receive(:puts)
          .with("'manual-slug/6-section' to 'manual-slug/1-section'")
        expect(logger).to receive(:puts)
          .with("'manual-slug/5-section' to 'manual-slug/2-section'")
        expect(logger).to receive(:puts)
          .with("The following sections cannot be reslugged:")
        expect(logger).to receive(:puts)
          .with("'manual-slug/4-section' would change to 'manual-slug/3-section' but this is already in use.")
        expect(logger).to receive(:puts)
          .with("'manual-slug/3-section' would change to 'manual-slug/4-section' but this is already in use.")
      end
    end

    describe "synchronise" do
      let(:reslugger) { double(:reslugger, call: nil) }

      it "calls SectionReslugger to reslug non-conflicting sections" do
        allow(logger).to receive(:puts).with(anything)

        expect(SectionReslugger).to receive(:new)
          .with("manual-slug", "manual-slug/6-section", "manual-slug/1-section")
          .and_return(reslugger)
        expect(SectionReslugger).to receive(:new)
          .with("manual-slug", "manual-slug/5-section", "manual-slug/2-section")
          .and_return(reslugger)

        subject.synchronise
      end
    end
  end

  context "when sections are in sync" do
    before do
      section_uuids = []

      2.times do |n|
        count = n + 1
        section_uuid = "section-uuid-#{count}"
        section_uuids << section_uuid

        SectionEdition.create!(
          section_uuid: section_uuid,
          slug: "manual-slug/#{count}-section",
          title: "#{count}. Section",
          summary: "Section summary",
          body: "Section body",
        )
      end

      manual_record.editions.create!(
        section_uuids: section_uuids,
      )
    end

    describe "report" do
      after { subject.report }

      it "Reports that sections are in sync" do
        expect(logger).to receive(:puts)
          .with("All section slugs are in sync with their titles.")
      end
    end

    describe "synchronise" do
      it "doesn't attempt to reslug anything" do
        allow(logger).to receive(:puts).with(anything)

        expect(SectionReslugger).not_to receive(:new)
          .with(anything)

        subject.synchronise
      end
    end
  end
end
