require "spec_helper"

describe ManualWithdrawer do
  let(:logger) { double(:logger) }

  subject do
    described_class.new(logger)
  end

  it "raises error when Manual is not found" do
    expect {
      subject.execute("non-existant-id")
    }.to raise_error(RuntimeError, "Manual not found for manual_id `non-existant-id`")
  end
end
