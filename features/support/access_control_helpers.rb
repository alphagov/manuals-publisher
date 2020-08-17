module AccessControlHelpers
  def check_manual_visible(title)
    expect(page).to have_content(title)
  end

  def check_manual_not_visible(title)
    expect(page).to_not have_content(title)
  end
end

RSpec.configuration.include AccessControlHelpers, type: :feature
World(AccessControlHelpers) if respond_to?(:World)
