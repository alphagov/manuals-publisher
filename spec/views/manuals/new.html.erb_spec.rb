describe "manuals/new", type: :view do
  it "links the cancel button to the 'Your manuals' page" do
    view_manual = ManualViewAdapter.new(FactoryBot.build(:manual))
    allow(view).to receive(:current_user).and_return(FactoryBot.build_stubbed(:user))

    render template: "manuals/new", layout: "layouts/design_system", locals: { manual: view_manual }

    expect(rendered).to have_link("Cancel", href: "/manuals")
  end
end
