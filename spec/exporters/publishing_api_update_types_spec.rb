require "spec_helper"

describe PublishingAPIUpdateTypes do
  subject { Class.new { include PublishingAPIUpdateTypes }.new }

  it "raises an argument error if update_type is supplied, but not a valid choice" do
    expect {
      subject.check_update_type!("reticulate-splines")
    }.to raise_error(ArgumentError, "update_type 'reticulate-splines' not recognised")
  end

  it "accepts major, minor, and republish as options for update_type" do
    PublishingAPIUpdateTypes::UPDATE_TYPES.each do |update_type|
      expect {
        subject.check_update_type!(update_type)
      }.not_to raise_error
    end
  end

  it "accepts explicitly setting nil as the option for update_type" do
    expect {
      subject.check_update_type!(nil)
    }.not_to raise_error
  end
end
