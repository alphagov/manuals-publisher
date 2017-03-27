When(/^I remove the section from the manual$/) do
  withdraw_section(@manual_fields.fetch(:title), @section_fields.fetch(:section_title))
  @removed_document = @document
end

When(/^I remove the edited section from the manual$/) do
  withdraw_section(@manual_fields.fetch(:title), @updated_fields.fetch(:section_title))
  @removed_document = @updated_section
end

When(/^I remove one of the sections from the manual$/) do
  withdraw_section(@manual_fields.fetch(:title), @sections.first.title)
  @removed_document = @sections.first
end

When(/^I remove one of the sections from the manual with a major update omitting the note$/) do
  withdraw_section(@manual_fields.fetch(:title), @sections.first.title, minor_update: false)
  @removed_document = @sections.first
end

When(/^I remove one of the sections from the manual with a major update$/) do
  withdraw_section(@manual_fields.fetch(:title), @sections.first.title, minor_update: false, change_note: "Removing #{@sections.first.title} section as content is covered elsewhere.")
  @removed_document = @sections.first
end

When(/^I remove one of the sections from the manual with a minor update$/) do
  withdraw_section(@manual_fields.fetch(:title), @sections.first.title, minor_update: true, change_note: "Should never have published this section, let's pretend we never did with this secret removal.")
  @removed_document = @sections.first
end

Then(/^the section is removed from the manual$/) do
  check_section_was_removed(@manual.id, @removed_document.id)
  check_draft_has_been_discarded_in_publishing_api(@removed_document.id)

  # Check that no child section has the removed document's title
  without_removed_document_matcher = ->(request) do
    data = JSON.parse(request.body)
    contents = data["details"]["child_section_groups"].first
    contents["child_sections"].none? do |child_section|
      child_section["title"] == @removed_document.title
    end
  end

  check_manual_is_drafted_to_publishing_api(@manual.id, with_matcher: without_removed_document_matcher)
end

Then(/^the removed section is not published$/) do
  check_manual_was_published(@manual)
  check_section_was_not_published(@removed_document)
end

Then(/^the removed section is withdrawn with a redirect to the manual$/) do
  check_manual_was_published(@manual)
  check_section_was_withdrawn_with_redirect(@removed_document, "/#{@manual.slug}")
end

Then(/^the removed section is archived$/) do
  check_section_is_archived_in_db(@manual, @removed_document.id)
end

Then(/^the removed section change note is included$/) do
  @removed_document = section_repository(@manual).fetch(@removed_document.id)

  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    with_matcher: change_notes_sent_to_publishing_api_include_document(@removed_document),
    number_of_drafts: 1
  )
end

Then(/^the removed section change note is not included$/) do
  @removed_document = section_repository(@manual).fetch(@removed_document.id)

  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    number_of_drafts: 0,
    with_matcher: change_notes_sent_to_publishing_api_include_document(@removed_document)
  )
end
