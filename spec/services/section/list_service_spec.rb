require "spec_helper"

RSpec.describe Section::ListService do
  it "returns the manual and its sections" do
    user = FactoryBot.build(:user, organisation_slug: "org-slug")
    manual = FactoryBot.build(:manual, organisation_slug: user.organisation_slug)
    section = manual.build_section(title: "section-title")
    manual.save!(user)

    service = Section::ListService.new(user: user, manual_id: manual.id)

    returned_manual, returned_sections = service.call

    expect(returned_manual).to eql(manual)
    expect(returned_sections).to eql([section])
  end
end
