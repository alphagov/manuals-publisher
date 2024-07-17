describe "shared/_govspeak_help", type: :view do
  it "renders the help without a collapsible help section by default" do
    render

    expect(rendered).not_to have_text("Collapsible")
    expect(rendered).to have_text("Paste and convert to Markdown")
    expect(rendered).to have_text("Headings")
    expect(rendered).to have_text("Links")
    expect(rendered).to have_text("Bullets")
    expect(rendered).to have_text("Numbered lists")
    expect(rendered).to have_text("Video links")
    expect(rendered).to have_text("Legislative list")
    expect(rendered).to have_text("Tables")
    expect(rendered).to have_text("Charts")
    expect(rendered).to have_text("Call to action")
    expect(rendered).to have_text("Abbreviations and acronyms")
    expect(rendered).to have_text("Blockquotes")
    expect(rendered).to have_text("Addresses")
    expect(rendered).to have_text("Email links")
    expect(rendered).to have_text("Footnotes")
  end

  it "renders the help with a collapsible help section" do
    render partial: "shared/govspeak_help", locals: { show_collapsible_help: true }

    expect(rendered).to have_text("Collapsible")
    expect(rendered).to have_text("Paste and convert to Markdown")
    expect(rendered).to have_text("Headings")
    expect(rendered).to have_text("Links")
    expect(rendered).to have_text("Bullets")
    expect(rendered).to have_text("Numbered lists")
    expect(rendered).to have_text("Video links")
    expect(rendered).to have_text("Legislative list")
    expect(rendered).to have_text("Tables")
    expect(rendered).to have_text("Charts")
    expect(rendered).to have_text("Call to action")
    expect(rendered).to have_text("Abbreviations and acronyms")
    expect(rendered).to have_text("Blockquotes")
    expect(rendered).to have_text("Addresses")
    expect(rendered).to have_text("Email links")
    expect(rendered).to have_text("Footnotes")
  end
end
