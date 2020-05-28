require "spec_helper"

describe LinkCheckReport, type: :model do
  let(:attributes) do
    {
      links: [{ uri: "http://www.example.com", status: "error" }],
      batch_id: 1,
      status: "error",
      manual_id: "1",
      section_id: "1",
      completed_at: Time.zone.parse("2017-12-01"),
    }
  end

  subject(:link_check_report) { LinkCheckReport.new(attributes) }

  context "all fields set" do
    it { should be_valid }
  end

  it "should be valid without a section id" do
    link_check_report.section_id = nil
    expect(link_check_report).to be_valid
  end

  it "should be valid without a completed at time" do
    link_check_report.completed_at = nil
    expect(link_check_report).to be_valid
  end

  it "should be invalid without a manual id" do
    link_check_report.manual_id = nil
    expect(link_check_report).not_to be_valid
  end

  it "should be invalid without links" do
    link_check_report.links = nil
    expect(link_check_report).not_to be_valid
  end

  it "should be invalid without a batch id" do
    link_check_report.batch_id = nil
    expect(link_check_report).not_to be_valid
  end

  it "should be invalid without a status" do
    link_check_report.status = nil
    expect(link_check_report).not_to be_valid
  end
end
