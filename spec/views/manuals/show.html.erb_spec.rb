require "spec_helper"

describe "manuals/show", type: :view do
  before do
    allow(view).to receive(:current_user_is_gds_editor?).and_return(true)
    allow(view).to receive(:current_user_can_publish?).and_return(true)
  end

  it "does not render the discard button for a published manual" do
    manual = FactoryBot.build_stubbed(:manual, ever_been_published: true)
    manual.publish_tasks = []

    render template: "manuals/show", locals: { manual:, slug_unique: true, clashing_sections: [] }

    expect(rendered).not_to match(/Discard draft/)
  end

  it "renders the discard button for an unpublished manual" do
    manual = FactoryBot.build_stubbed(:manual, ever_been_published: false)
    manual.publish_tasks = []

    render template: "manuals/show", locals: { manual:, slug_unique: true, clashing_sections: [] }

    expect(rendered).to match(/Discard draft/)
  end

  [
    [:notice, ".govuk-notification-banner .govuk-notification-banner__content"],
    [:success, ".govuk-notification-banner .govuk-notification-banner__content"],
    [:error, ".gem-c-error-alert .gem-c-error-alert__message"],
  ].each do |flash_type, msg_css_selector|
    it "renders a #{flash_type} flash message" do
      manual = FactoryBot.build_stubbed(:manual)
      manual.publish_tasks = []
      msg = "A flash message"
      flash[flash_type] = msg
      allow(view).to receive(:flash).and_return(flash)
      allow(view).to receive(:current_user).and_return(FactoryBot.build_stubbed(:user))

      render template: "manuals/show",
             layout: "layouts/design_system",
             locals: { manual:, slug_unique: true, clashing_sections: [] }

      expect(rendered).to have_css(msg_css_selector, text: msg)
    end
  end
end
