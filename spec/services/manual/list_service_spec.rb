require "spec_helper"

RSpec.describe Manual::ListService do
  let(:user) { double(:user) }

  subject do
    Manual::ListService.new(
      user: user,
    )
  end

  it "loads all manuals for the user" do
    expect(Manual).to receive(:all).with(user, anything)

    subject.call
  end

  it "avoids loading manual associations" do
    expect(Manual).to receive(:all).with(anything, load_associations: false)

    subject.call
  end
end
