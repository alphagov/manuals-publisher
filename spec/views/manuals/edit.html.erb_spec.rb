require "spec_helper"

describe "manuals/edit", type: :view do
  it "sets the page title" do
    view_manual = ManualViewAdapter.new(FactoryBot.build_stubbed(:manual, title: "a"))
    allow(view).to receive(:current_user).and_return(FactoryBot.build_stubbed(:user))

    render template: "manuals/edit", layout: "layouts/design_system", locals: { manual: view_manual }

    expect(rendered).to have_title("Edit manual - GOV.UK Manuals Publisher")
  end

  %w[title summary body].each do |attribute|
    it "links an error summary message for the #{attribute} input field" do
      invalid_manual = FactoryBot.build_stubbed(:manual, title: "", summary: "", body: "<script></script>")
      invalid_manual.valid?
      view_manual = ManualViewAdapter.new(invalid_manual)

      render template: "manuals/edit", locals: { manual: view_manual }

      expect(rendered).to have_link(href: "#manual_#{attribute}")
      expect(rendered).to have_field("manual_#{attribute}")
    end

    it "does not render an error summary message for #{attribute} field when it is valid" do
      valid_manual = FactoryBot.build_stubbed(:manual, title: "a", summary: "b", body: "")
      valid_manual.valid?
      view_manual = ManualViewAdapter.new(valid_manual)

      render template: "manuals/edit", locals: { manual: view_manual }

      expect(rendered).not_to have_link(href: "#manual_#{attribute}")
      expect(rendered).to have_field("manual_#{attribute}")
    end
  end

  it "links the cancel button to the manual's show page" do
    manual = FactoryBot.build_stubbed(:manual, updated_at: Time.zone.now)
    view_manual = ManualViewAdapter.new(manual)
    allow(view).to receive(:current_user).and_return(FactoryBot.build_stubbed(:user))

    render template: "manuals/new", layout: "layouts/design_system", locals: { manual: view_manual }

    expect(rendered).to have_link("Cancel", href: "/manuals/#{manual.id}")
  end
end
