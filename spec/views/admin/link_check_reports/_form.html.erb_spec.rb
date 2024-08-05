describe "admin/link_check_reports/_form", type: :view do
  it "renders a button with the specified text" do
    allow(view).to receive(:reportable).and_return({})
    allow(view).to receive(:button_text).and_return("Do the thing")

    render

    expect(rendered).to have_css("button", exact_text: "Do the thing")
  end
end
