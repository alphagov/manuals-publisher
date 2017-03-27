When(/^I attach a file and give it a title$/) do
  @attachment_title = "My attachment"
  add_attachment_to_section(@section_title, @attachment_title)
end

Then(/^I can see a link to the file with the title in the section preview$/) do
  check_preview_contains_attachment_link(@attachment_title)
end

When(/^I edit the attachment$/) do
  @new_attachment_title = "And now for something completely different"
  @new_attachment_file_name = "text_file.txt"

  edit_attachment(
    @section_title,
    @attachment_title,
    @new_attachment_title,
    @new_attachment_file_name,
  )
end

Then(/^I see the updated attachment on the section edit page$/) do
  check_for_attachment_update(
    @section_title,
    @new_attachment_title,
    @new_attachment_file_name,
  )
end

Then(/^I see the attached file$/) do
  check_for_an_attachment
end
