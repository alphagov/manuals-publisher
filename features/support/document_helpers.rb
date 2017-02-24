module DocumentHelpers
  def save_document
    click_on "Save as draft"
  end

  def generate_preview
    click_button("Preview")
  end

  def check_content_preview_link(slug)
    preview_url = "#{Plek.current.find('draft-origin')}/#{slug}"
    expect(page).to have_link("Preview draft", href: preview_url)
  end

  def check_live_link(slug)
    live_url = "#{Plek.current.website_root}/#{slug}"
    expect(page).to have_link("View on website", href: live_url)
  end

  def check_for_javascript_usage_error(field)
    expect(page).to have_content("#{field} cannot include invalid Govspeak, invalid HTML, any JavaScript or images hosted on sites except for")
  end

  def check_for_slug_clash_warning
    expect(page).to have_content("You can't publish it until you change the title.")
  end
end
RSpec.configuration.include DocumentHelpers, type: :feature
