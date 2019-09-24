require "spec_helper"

describe "sections/_form.html.erb", type: :view do
  it "contains the elements required by the JavaScript that toggles the visibility of the change note field" do
    manual = FactoryBot.build(:manual, id: "manual-id")
    section = Section.new(manual: manual, uuid: "section-uuid")

    allow(manual).to receive(:has_ever_been_published?).and_return(true)

    section_view_adapter = SectionViewAdapter.new(manual, section)
    allow(section_view_adapter).to receive(:accepts_minor_updates?).and_return(true)

    allow(view).to receive(:manual).and_return(ManualViewAdapter.new(manual))
    allow(view).to receive(:section).and_return(section_view_adapter)

    render

    expect(rendered).to have_css("#section_minor_update_0")
    expect(rendered).to have_css("#section_minor_update_1")
    expect(rendered).to have_css("#section_change_note")
  end
end
