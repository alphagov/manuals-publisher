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
end
