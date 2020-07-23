require "spec_helper"

RSpec.describe Section::NewService do
  it "returns the manual and a new section" do
    user = FactoryBot.build(:user, organisation_slug: "org-slug")
    manual = FactoryBot.build(:manual, organisation_slug: user.organisation_slug)
    manual.save!(user)

    service = Section::NewService.new(user: user, manual_id: manual.id)

    returned_manual, returned_section = service.call

    expect(returned_manual).to eql(manual)
    expect(returned_manual.sections).to include(returned_section)
  end
end
