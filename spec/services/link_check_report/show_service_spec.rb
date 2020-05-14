require "spec_helper"

RSpec.describe LinkCheckReport::ShowService do
  let(:link_check_report) do
    FactoryBot.create(
      :link_check_report,
      :with_broken_links,
      manual_id: 1,
      batch_id: 1,
    )
  end

  let(:link_check_report_id) { link_check_report.id }

  context "when the link checker api is called with a manual" do
    subject { described_class.new(id: link_check_report_id) }

    it "returns the report" do
      expect(subject.call).to be_a_kind_of(LinkCheckReport)
    end
  end
end
