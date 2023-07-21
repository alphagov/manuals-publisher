When(/^I visit the homepage before November 2023$/) do
  travel_to(Date.new(2023, 10, 31))
  visit "/"
end

When(/^I click on "(.*)"$/) do |link|
  click_on link
end

Then(/^I can see what is new in Manuals Publisher$/) do
  expect(page).to have_content("New Manuals Publisher features")
end
