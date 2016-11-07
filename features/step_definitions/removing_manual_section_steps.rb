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

  WebMock::RequestRegistry.instance.reset!
end

Then(/^the document is removed from the manual$/) do
  check_manual_section_was_removed(@manual.id, @document.id)
end
