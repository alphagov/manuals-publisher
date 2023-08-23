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
end
