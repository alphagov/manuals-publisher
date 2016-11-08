When(/^I remove the document from the manual$/) do
  withdraw_manual_document(@manual_fields.fetch(:title), @document_fields.fetch(:section_title))
  @removed_document = @document
end

When(/^I remove the edited document from the manual$/) do
  withdraw_manual_document(@manual_fields.fetch(:title), @updated_fields.fetch(:section_title))
  @removed_document = @updated_document
end

When(/^I remove one of the documents from the manual$/) do
  withdraw_manual_document(@manual_fields.fetch(:title), @documents.first.title)
  @removed_document = @documents.first
end

Then(/^the document is removed from the manual$/) do
  check_manual_section_was_removed(@manual.id, @removed_document.id)
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

Then(/^the removed document is not published$/) do
  check_manual_was_published(@manual)
  check_manual_document_was_not_published(@removed_document)
end

Then(/^the removed document is withdrawn with a redirect to the manual$/) do
  check_manual_was_published(@manual)
  check_manual_document_was_withdrawn_with_redirect(@removed_document, "/#{@manual.slug}")
end

Then(/^the removed document is archived$/) do
  check_manual_document_is_archived_in_db(@manual, @removed_document.id)
end
