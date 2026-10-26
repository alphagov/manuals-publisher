describe "manuals/confirm_discard", type: :view do
  it "explains that a previously published manual will revert to the version on GOV.UK" do
    manual = FactoryBot.build_stubbed(:manual, ever_been_published: true)

    render template: "manuals/confirm_discard", locals: { manual: }

    expect(rendered).to match(/revert it to the version currently on GOV.UK/)
  end

  it "does not mention reverting for a manual that has never been published" do
    manual = FactoryBot.build_stubbed(:manual, ever_been_published: false)

    render template: "manuals/confirm_discard", locals: { manual: }

    expect(rendered).not_to match(/revert/)
  end
end
