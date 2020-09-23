require "spec_helper"

RSpec.describe "manual urls", type: :feature do
  before do
    login_as(:gds_editor)
  end

  let!(:manual) { create_manual_without_ui({ title: "A manual", summary: "A manual summary", body: "A manual body" }) }
  let!(:section) { create_section_without_ui(manual, { title: "Section 1", summary: "A section summary", body: "A section body" }) }

  it "should respond with 'OK'" do
    visit "/manuals"

    expect(page).to have_link("A manual", href: %r{/manuals/#{manual.id}$})

    click_on "A manual"

    expect(page).to have_link("Edit manual", href: %r{/manuals/#{manual.id}/edit$})
    expect(page).to have_link("Section 1", href: %r{/manuals/#{manual.id}/sections/#{section.uuid}$})

    click_on "Section 1"

    expect(page).to have_link("Edit section", href: %r{/manuals/#{manual.id}/sections/#{section.uuid}/edit$})
  end
end
