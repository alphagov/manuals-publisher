When(/^I run the manual section removal script$/) do
  @stdin = double(:stdin)
  null_stdout = double(:null_output_io, puts: nil)
  null_stderr = double(:null_output_io, puts: nil)

  @remover = CliManualSectionRemover.new(
    manual_id: @manual.id,
    section_id: @section.id,
    options: {
      stdin: @stdin,
      stdout: null_stdout,
      stderr: null_stderr,
    },
  )
end

When(/^I confirm removal$/) do
  allow(@stdin).to receive(:gets).and_return("y")
  @remover.call
end

When(/^I refuse removal$/) do
  allow(@stdin).to receive(:gets).and_return("No")
  expect { @remover.call }.to raise_error
end

Then(/^the manual section is removed$/) do
  check_manual_section_was_removed(@manual.id, @section.id)
end

Then(/^the manual section still exists$/) do
  check_manual_section_exists(@manual.id, @section.id)
end

When(/^I remove the document from the manual$/) do
  withdraw_manual_document(@manual_fields.fetch(:title), @document_fields.fetch(:section_title))
  @removed_document = @document
end

When(/^I remove the edited document from the manual$/) do
  withdraw_manual_document(@manual_fields.fetch(:title), @updated_fields.fetch(:section_title))
  @removed_document = @updated_document
end

Then(/^the document is removed from the manual$/) do
  check_manual_section_was_removed(@manual.id, @removed_document.id)
  check_draft_has_been_discarded_in_publishing_api(@removed_document.id)
end

Then(/^the removed document is not published$/) do
  check_manual_was_published(@manual)
  check_manual_document_was_not_published(@removed_document)
end

Then(/^the removed document is withdrawn with a redirect to the manual$/) do
  check_manual_was_published(@manual)
  check_manual_document_was_withdrawn_with_redirect(@removed_document, "/#{@manual.slug}")
end
