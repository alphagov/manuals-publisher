When(/^I remove the section from the manual$/) do
  withdraw_section(@manual_fields.fetch(:title), @section_fields.fetch(:section_title))
  @removed_section = @section
end

When(/^I remove the edited section from the manual$/) do
  withdraw_section(@manual_fields.fetch(:title), @updated_fields.fetch(:section_title))
  @removed_section = @updated_section
end

When(/^I remove one of the sections from the manual$/) do
  withdraw_section(@manual_fields.fetch(:title), @sections.first.title)
  @removed_section = @sections.first
end

When(/^I remove one of the sections from the manual with a major update omitting the note$/) do
  withdraw_section(@manual_fields.fetch(:title), @sections.first.title, minor_update: false)
  @removed_section = @sections.first
end

When(/^I remove one of the sections from the manual with a major update$/) do
  withdraw_section(@manual_fields.fetch(:title), @sections.first.title, minor_update: false, change_note: "Removing #{@sections.first.title} section as content is covered elsewhere.")
  @removed_section = @sections.first
end

When(/^I remove one of the sections from the manual with a minor update$/) do
  withdraw_section(@manual_fields.fetch(:title), @sections.first.title, minor_update: true, change_note: "Should never have published this section, let's pretend we never did with this secret removal.")
  @removed_section = @sections.first
end

Then(/^the section is removed from the manual$/) do
  check_section_was_removed(@manual.id, @removed_section.uuid)
  check_draft_has_been_discarded_in_publishing_api(@removed_section.uuid)

  # Check that no child section has the removed section's title
  without_removed_section_matcher = lambda do |request|
    data = JSON.parse(request.body)
    contents = data["details"]["child_section_groups"].first
    contents["child_sections"].none? do |child_section|
      child_section["title"] == @removed_section.title
    end
  end

  check_manual_is_drafted_to_publishing_api(@manual.id, with_matcher: without_removed_section_matcher)
end

Then(/^the removed section is not published$/) do
  check_manual_was_published(@manual)
  check_section_was_not_published(@removed_section)
end

Then(/^the removed section is withdrawn with a redirect to the manual$/) do
  check_manual_was_published(@manual)
  check_section_was_withdrawn_with_redirect(@removed_section, "/#{@manual.slug}")
end

Then(/^the removed section is archived$/) do
  check_section_is_archived_in_db(@manual, @removed_section.uuid)
end

Then(/^the removed section change note is included$/) do
  @removed_section = Section.find(@manual, @removed_section.uuid)

  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    with_matcher: change_notes_sent_to_publishing_api_include_section(@removed_section),
    number_of_drafts: 1,
  )
end

Then(/^the removed section change note is not included$/) do
  @removed_section = Section.find(@manual, @removed_section.uuid)

  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    number_of_drafts: 0,
    with_matcher: change_notes_sent_to_publishing_api_include_section(@removed_section),
  )
end
