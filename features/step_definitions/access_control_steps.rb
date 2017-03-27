Given(/^I am logged in as a GDS editor$/) do
  login_as(:gds_editor)
  stub_organisation_details(GDS::SSO.test_user.organisation_slug)
end

Given(/^I am logged in as an editor$/) do
  login_as(:generic_editor)
  stub_organisation_details(GDS::SSO.test_user.organisation_slug)
end

Given(/^there are manuals created by multiple organisations$/) do
  login_as(:generic_editor_of_another_organisation)
  stub_organisation_details(GDS::SSO.test_user.organisation_slug)
  @coffee_manual_fields = {
    title: "Manual on Coffee",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }
  create_manual(@coffee_manual_fields)

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
  check_manual_not_visible(@coffee_manual_fields.fetch(:title))
end

Then(/^I see manuals created by all organisations$/) do
  check_manual_visible(@tea_manual_fields.fetch(:title))
  check_manual_visible(@coffee_manual_fields.fetch(:title))
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

Then(/^I cannot remove a section from the manual$/) do
  check_section_withdraw_link_not_visible(@manual, @sections.first)
end
