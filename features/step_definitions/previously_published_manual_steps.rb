Given(/^I create a manual that was previously published elsewhere$/) do
  WebMock::RequestRegistry.instance.reset!
  @manual_fields = {
    title: "Example Manual Title",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
    body: "This was originally published on [another site](http://www.example.com).",
  }
  @manual_slug = "guidance/example-manual-title"

  @originally_published_at = Time.zone.parse("14-Dec-#{Time.zone.now.year - 10} 09:30")

  create_manual(@manual_fields) do
    choose("This document has previously been published on another website")
    fill_in "Year", with: @originally_published_at.year.to_s
    fill_in "Month", with: @originally_published_at.mon.to_s
    fill_in "Day", with: @originally_published_at.day.to_s
    page.select sprintf("%02d", @originally_published_at.hour), from: "Hour"
    page.select sprintf("%02d", @originally_published_at.min.to_s), from: "Minute"
  end

  @manual = most_recently_created_manual

  step %(a draft section exists for the manual)
end

When(/^I tell the manual to stop using the previously published date as the public date$/) do
  WebMock::RequestRegistry.instance.reset!

  edit_manual_original_publication_date(@manual.title) do
    choose("Change the first published date")
  end

  step %(I publish the manual)
end

When(/^I update the previously published date to a new one$/) do
  WebMock::RequestRegistry.instance.reset!

  @new_originally_published_at = Time.zone.parse("25-Mar-#{Time.zone.now.year - 8} 12:57")

  edit_manual_original_publication_date(@manual.title) do
    fill_in "Year", with: @new_originally_published_at.year.to_s
    fill_in "Month", with: @new_originally_published_at.mon.to_s
    fill_in "Day", with: @new_originally_published_at.day.to_s
    page.select @new_originally_published_at.hour.to_s, from: "Hour"
    page.select @new_originally_published_at.min.to_s, from: "Minute"
  end

  step %(I publish the manual)
end

When(/^I update the manual to clear the previously published date$/) do
  WebMock::RequestRegistry.instance.reset!

  edit_manual_original_publication_date(@manual.title) do
    fill_in "Year", with: ""
    fill_in "Month", with: ""
    fill_in "Day", with: ""
    page.select "", from: "Hour"
    page.select "", from: "Minute"
  end

  step %(I publish the manual)
end

When(/^I tell the manual to start using the previously published date as the public date$/) do
  WebMock::RequestRegistry.instance.reset!

  edit_manual_original_publication_date(@manual.title) do
    choose("Change the first published and last updated date")
  end

  step %(I publish the manual)
end

When(/^I publish a minor change to the manual$/) do
  steps %(
    When I edit one of the manual's sections as a minor change
    And I publish the manual
  )
end

When(/^I publish a major change to the manual$/) do
  steps %(
    When I edit one of the manual's sections as a major change
    And I publish the manual
  )
end

Then(/^the manual and its sections are (re|)published with all public timestamps set to the previously published date$/) do |republished|
  how_many_times = (republished == "re" ? 2 : 1)

  check_manual_is_drafted_and_published_with_all_public_timestamps(@manual, @originally_published_at, how_many_times:)
  check_section_is_drafted_and_published_with_all_public_timestamps(@section, @originally_published_at, how_many_times:)
end

Then(/^the manual and its sections are (re|)published with the first published timestamp set to the previously published date, but not the public updated timestamp$/) do |republished|
  how_many_times = (republished == "re" ? 2 : 1)

  check_manual_is_drafted_and_published_with_first_published_date_only(@manual, @originally_published_at, how_many_times:)
  check_section_is_drafted_and_published_with_first_published_date_only(@section, @originally_published_at, how_many_times:)
end

Then(/^the manual and its sections are (re|)published with all public timestamps set to the new previously published date$/) do |republished|
  how_many_times = (republished == "re" ? 2 : 1)

  check_manual_is_drafted_and_published_with_all_public_timestamps(@manual, @new_originally_published_at, how_many_times:)
  check_section_is_drafted_and_published_with_all_public_timestamps(@section, @new_originally_published_at, how_many_times:)
end

Then(/^the manual and its sections are (re|)published with the first published timestamp set to the new published date, but not the public updated timestamp$/) do |republished|
  how_many_times = (republished == "re" ? 2 : 1)

  check_manual_is_drafted_and_published_with_first_published_date_only(@manual, @new_originally_published_at, how_many_times:)
  check_section_is_drafted_and_published_with_first_published_date_only(@section, @new_originally_published_at, how_many_times:)
end

Then(/^the manual and its sections are (re|)published without any public timestamps$/) do |republished|
  how_many_times = (republished == "re" ? 2 : 1)

  check_manual_is_drafted_and_published_with_no_public_timestamps(@manual, how_many_times:)
  check_manual_is_drafted_and_published_with_no_public_timestamps(@section, how_many_times:)
end
