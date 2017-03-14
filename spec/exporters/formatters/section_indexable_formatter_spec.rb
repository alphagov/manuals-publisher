require "spec_helper"
require "formatters/section_indexable_formatter"

RSpec.describe SectionIndexableFormatter do
  let(:section) {
    double(
      :manual_section,
      title: double,
      summary: double,
      slug: "",
      body: double,
    )
  }
  let(:manual) {
    double(
      :manual,
      title: double,
      organisation_slug: double,
      slug: "",
    )
  }

  subject(:formatter) { SectionIndexableFormatter.new(section, manual) }

  describe "as an indexable formatter" do
    it_behaves_like "an indexable formatter"
  end
end
