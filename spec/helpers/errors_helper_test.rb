require "spec_helper"

describe ErrorsHelper, type: :helper do
  describe "#errors_for" do
    before do
      @object_with_no_errors = ErrorTestObject.new("title", Time.zone.today)
      @object_with_errors = ErrorTestObject.new(nil, nil)
      @object_with_unrelated_errors = ErrorTestObject.new("title", nil)
      @object_with_errors.validate
      @object_with_unrelated_errors.validate
    end

    it "returns nil when there are no error messages" do
      expect(errors_for(@object_with_no_errors.errors, :title)).to be_nil
    end

    it "returns errors for the attribute passed in" do
      expect(errors_for(@object_with_errors.errors, :title)).to contain_exactly({ text: "Title can't be blank" })
    end

    it "formats the error message when there are multiple errors on a field" do
      expect(errors_for(@object_with_errors.errors, :date)).to contain_exactly({ text: "Date can't be blank" }, { text: "Date is invalid" })
    end

    it "does not return an empty string when object has unrelated error" do
      expect(errors_for(@object_with_unrelated_errors.errors, :title)).to be_nil
    end
  end
end

class ErrorTestObject
  include ActiveModel::Model
  attr_accessor :title, :date

  validates :title, :date, presence: true
  validate :date_is_a_date

  def initialize(title, date)
    @title = title
    @date = date
  end

  def date_is_a_date
    errors.add(:date, :invalid) unless date.is_a?(Date)
  end
end
