When(/^I create a AAIB report$/) do
  @document_title = "Example AAIB Report"
  @slug = "aaib-reports/example-aaib-report"
  @aaib_fields = {
    title: @document_title,
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
    body: "## Header" + ("\n\nPraesent commodo cursus magna, vel scelerisque nisl consectetur et." * 10),
    date_of_occurrence: "2014-01-01"
  }

  create_document(@aaib_fields)
end

Then(/^the AAIB report has been created$/) do
  check_document_exists_with(@aaib_fields)
  check_slug_registered_with_panopticon_with_correct_organisation(@slug, ["air-accidents-investigation-branch"])
end

When(/^I create a AAIB report without one of the required fields$/) do
  @aaib_fields = {
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }

  create_document(@aaib_fields)
end

Then(/^the AAIB report should not have been created$/) do
  check_document_does_not_exist_with(@aaib_fields)
end

Given(/^two AAIB reports exist$/) do
  @aaib_fields = {
    title: "AAIB Report 1",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
    body: "## Header" + ("\n\nPraesent commodo cursus magna, vel scelerisque nisl consectetur et." * 10),
    date_of_occurrence: "2014-01-01"
  }
  create_document(@aaib_fields)

  @aaib_fields = {
    title: "AAIB Report 2",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
    body: "## Header" + ("\n\nPraesent commodo cursus magna, vel scelerisque nisl consectetur et." * 10),
    date_of_occurrence: "2014-01-01"
  }
  create_document(@aaib_fields)
end

Then(/^the AAIB reports should be in the publisher report index in the correct order$/) do
  visit specialist_documents_path

  check_for_documents("AAIB Report 2", "AAIB Report 1")
end

Given(/^a draft AAIB report exists$/) do
  @document_title = "Example AAIB Report"
  @slug = "aaib-reports/example-aaib-report"
  @aaib_fields = {
    title: @document_title,
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
    body: "## Header" + ("\n\nPraesent commodo cursus magna, vel scelerisque nisl consectetur et." * 10),
    date_of_occurrence: "2014-01-01"
  }

  create_document(@aaib_fields)
end

When(/^I edit a AAIB report$/) do
  @new_title = "Edited Example AAIB Report"
  edit_document(@document_title, title: @new_title)
end

Then(/^the AAIB report should have been updated$/) do
  check_for_new_title(@new_title)
end
