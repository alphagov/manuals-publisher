require "spec_helper"

describe "sections/withdraw.html.erb", type: :view do
  it "contains the elements required by the JavaScript that toggles the visibility of the change note field" do
    manual = FactoryBot.build(:manual, id: "manual-id")
    section = Section.new(manual: manual, uuid: "section-uuid")

    allow(view).to receive(:manual).and_return(ManualViewAdapter.new(manual))
    allow(view).to receive(:section).and_return(SectionViewAdapter.new(manual, section))

    render

    expect(rendered).to have_css("#section_minor_update_0")
    expect(rendered).to have_css("#section_minor_update_1")
    expect(rendered).to have_css("#section_change_note")
  end
end
