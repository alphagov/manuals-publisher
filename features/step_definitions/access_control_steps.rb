Given(/^I am logged in as a "(.*?)" editor$/) do |editor_type|
  login_as(:"#{editor_type.downcase}_editor")
  stub_organisation_details(GDS::SSO.test_user.organisation_slug)
end

Given(/^I am logged in as a non\-CMA editor$/) do
  login_as(:generic_editor)
  stub_organisation_details(GDS::SSO.test_user.organisation_slug)
end

Given(/^there are manuals created by multiple organisations$/) do
  login_as(:cma_editor)
  stub_organisation_details(GDS::SSO.test_user.organisation_slug)
  @cma_manual_fields = {
    title: "Manual on Competition",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }
  create_manual(@cma_manual_fields)

  login_as(:generic_editor)
  stub_organisation_details(GDS::SSO.test_user.organisation_slug)
  @tea_manual_fields = {
    title: "Manual on Tea",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }
  create_manual(@tea_manual_fields)
end

When(/^I view my list of manuals$/) do
  visit manuals_path
end

Then(/^I only see manuals created by my organisation$/) do
  check_manual_visible(@tea_manual_fields.fetch(:title))
  check_manual_not_visible(@cma_manual_fields.fetch(:title))
end

Then(/^I see manuals created by all organisations$/) do
  check_manual_visible(@tea_manual_fields.fetch(:title))
  check_manual_visible(@cma_manual_fields.fetch(:title))
end

Given(/^I am logged in as a writer$/) do
  login_as(:generic_writer)
  stub_organisation_details(GDS::SSO.test_user.organisation_slug)
end

Then(/^I can edit manuals$/) do
  check_manual_can_be_created
end

Then(/^I cannot publish manuals$/) do
  check_manual_cannot_be_published
end

Then(/^I cannot remove a document from the manual$/) do
  check_document_withdraw_link_not_visible(@manual, @documents.first)
end
