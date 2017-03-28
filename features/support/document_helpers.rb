module DocumentHelpers
  def check_for_javascript_usage_error(field)
    expect(page).to have_content("#{field} cannot include invalid Govspeak, invalid HTML, any JavaScript or images hosted on sites except for")
  end
end
RSpec.configuration.include DocumentHelpers, type: :feature
