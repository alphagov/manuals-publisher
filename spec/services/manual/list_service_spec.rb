require "spec_helper"

RSpec.describe Manual::ListService do
  let(:user) { FactoryBot.create(:gds_editor) }

  subject do
    Manual::ListService.new(
      user: user,
    )
  end

  it "loads all manuals for the user" do
    expect(Manual).to receive(:all).with(user, anything).and_return([])

    subject.call
  end

  it "avoids loading manual associations" do
    expect(Manual).to receive(:all).with(anything, load_associations: false).and_return([])

    subject.call
  end

  it "returns all manuals" do
    expect(subject.call).to eq([])
  end

  it "only returns 15 results" do
    manuals = (1..100).to_a
    expected_manuals = (1..25).to_a

    expect(Manual).to receive(:all).with(user, anything).and_return(manuals)

    expect(subject.call).to eq(expected_manuals)
  end
end
