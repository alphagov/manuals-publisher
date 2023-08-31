require "spec_helper"

describe "manuals/edit", type: :view do
  it "sets the page title" do
    view_manual = ManualViewAdapter.new(FactoryBot.build_stubbed(:manual, title: "a"))
    allow(view).to receive(:current_user).and_return(FactoryBot.build_stubbed(:user))

    render template: "manuals/edit", layout: "layouts/design_system", locals: { manual: view_manual }

    expect(rendered).to have_title("Edit manual - GOV.UK Manuals Publisher")
  end
end
