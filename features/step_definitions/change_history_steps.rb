When(/^I visit the change history page for the manual$/) do
  go_to_manual_page(@manual.title)

  click_link "Change history"
end

Then(/^I see the change notes for the manual$/) do
  within "table" do
    @manual.publication_logs.each do |log|
      expect(page).to have_text(log.created_at.strftime("%B %d, %Y %-l:%M%P"))
      expect(page).to have_text(log.title)
      expect(page).to have_text(log.change_note)
    end
  end

  within "tbody" do
    @initial_publication_logs_count = @manual.publication_logs.count
    expect(page).to have_selector "tr", count: @initial_publication_logs_count
  end
end

When(/^I click delete on a change note$/) do
  @publication_log = @manual.publication_logs.first
  within page.find("td", text: @publication_log.title).ancestor("tr") do
    click_on "Delete"
  end
end

Then(/^I am redirected to the confirmation page$/) do
  expect(page).to have_text("Change published at: #{@publication_log.created_at.strftime('%B %d, %Y %-l:%M%P')}")
  expect(page).to have_text("Section title: #{@publication_log.title}")
  expect(page).to have_text("Current change note: #{@publication_log.change_note}")
end

When(/^I click the cancel button$/) do
  click_on "Cancel"
end

Then(/^I am redirected to the Change history page$/) do
  expect(page).to have_selector("h1", text: "Change history")
end

And(/^I can see that no change notes have been deleted$/) do
  within "tbody" do
    expect(page).to have_selector "tr", count: @initial_publication_logs_count
  end
  expect(page).to have_text @publication_log.title
end

And(/^I delete the change note$/) do
  click_on "Delete"
end

And(/^I can see that the change note has been deleted$/) do
  within "tbody" do
    expect(page).to have_selector "tr", count: @initial_publication_logs_count - 1
  end
  expect(page).not_to have_text @publication_log.title
end
