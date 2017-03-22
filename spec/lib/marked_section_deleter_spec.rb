require "spec_helper"
require "marked_section_deleter"

describe MarkedSectionDeleter do
  subject {
    described_class.new(StringIO.new)
  }

  it "doesn't raise any exceptions" do
    subject.execute
  end
end
