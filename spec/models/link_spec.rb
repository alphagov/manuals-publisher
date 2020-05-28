require "spec_helper"

describe Link do
  let(:attributes) do
    {
      uri: "http://www.example.com",
      status: "error",
      checked: Time.zone.parse("2017-12-01"),
      check_warnings: ["example check warnings"],
      check_errors: ["example check errors"],
      problem_summary: "example problem",
      suggested_fix: "example fix",
    }
  end

  subject(:link) { Link.new(attributes) }

  context "all fields set" do
    it { should be_valid }
  end

  it "should be valid without a checked time" do
    link.checked = nil
    expect(link).to be_valid
  end

  it "should be valid without check warnings" do
    link.check_warnings = nil
    expect(link).to be_valid
  end

  it "should be valid without check errors" do
    link.check_errors = nil
    expect(link).to be_valid
  end

  it "should be valid without a problem summary" do
    link.problem_summary = nil
    expect(link).to be_valid
  end

  it "should be valid without a suggested fix" do
    link.suggested_fix = nil
    expect(link).to be_valid
  end

  it "should be invalid without a uri" do
    link.uri = nil
    expect(link).not_to be_valid
  end

  it "should be invalid without a status" do
    link.status = nil
    expect(link).not_to be_valid
  end

  it "should store warnings as an array" do
    expect(link.check_warnings).to be_kind_of(Array)
  end

  it "should store errors as an array" do
    expect(link.check_errors).to be_kind_of(Array)
  end
end
