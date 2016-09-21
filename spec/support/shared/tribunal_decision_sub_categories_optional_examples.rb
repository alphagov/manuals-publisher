require "rails_helper"

RSpec.shared_examples_for "tribunal decision sub_categories optional" do

  context "when sub_categories not provided" do
    let(:categories) { [double] }
    let(:sub_categories) { nil }

    it "is valid" do
      expect(validatable.valid?).to be true
    end
  end

  context "when sub_categories present" do
    let(:categories) { [double] }
    let(:sub_categories) { [double] }

    it "is valid" do
      expect(validatable.valid?).to be true
    end
  end

  context "when categories not provided" do
    let(:categories) { nil }
    let(:sub_categories) { [double] }

    it "is not valid" do
      expect(validatable.valid?).to be false
    end
  end
end
