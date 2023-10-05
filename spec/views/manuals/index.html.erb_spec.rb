require "spec_helper"

describe "manuals/index", type: :view do
  it "shows the organisation slug if the user is a gds editor" do
    manuals = [FactoryBot.build_stubbed(:manual, organisation_slug: "Test organisation", updated_at: Time.zone.now)]
    allow(view).to receive(:current_user).and_return(FactoryBot.build_stubbed(:gds_editor))
    allow(view).to receive(:current_user_is_gds_editor?).and_return(true)

    render template: "manuals/index", layout: "layouts/design_system", locals: { manuals: }

    expect(rendered).to have_text("Test organisation")
  end

  it "does not show the organisation slug if the user is not a gds editor" do
    manuals = [FactoryBot.build_stubbed(:manual, organisation_slug: "Test organisation", updated_at: Time.zone.now)]
    allow(view).to receive(:current_user).and_return(FactoryBot.build_stubbed(:user))
    allow(view).to receive(:current_user_is_gds_editor?).and_return(false)

    render template: "manuals/index", layout: "layouts/design_system", locals: { manuals: }

    expect(rendered).not_to have_text("Test organisation")
  end
end
