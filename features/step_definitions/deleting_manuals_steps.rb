require "cli_manual_deleter"

When(/^I run the deletion script$/) do
  @stdin = double(:stdin)
  # If we cared about checking string output we'd make this a StringIO
  null_stdout = double(:null_output_io, puts: nil)
  @deleter = CliManualDeleter.new(manual_slug: @manual_slug, stdin: @stdin, stdout: null_stdout)
end

When(/^I confirm deletion/) do
  allow(@stdin).to receive(:gets).and_return("y")
  @deleter.call
end

Then(/^the script raises an error/) do
  expect { @deleter.call }.to raise_error(RuntimeError, /Cannot delete/)
end

Then(/^the manual and its sections are deleted$/) do
  check_manual_does_not_exist_with(@manual_fields)
  check_draft_has_been_discarded_in_publishing_api(@manual.id)
  check_draft_has_been_discarded_in_publishing_api(@section.uuid)
end

Then(/^the manual and its sections still exist$/) do
  check_manual_exists_with(@manual_fields)
end

When(/^I discard the draft manual$/) do
  discard_draft_manual(@manual.title)
end
