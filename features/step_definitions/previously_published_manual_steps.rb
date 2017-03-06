Given(/^I create a manual that was previously published elsewhere$/) do
  WebMock::RequestRegistry.instance.reset!
  @manual_fields = {
    title: "Example Manual Title",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
    body: "This was originally published on [another site](http://www.example.com)."
  }
  @manual_slug = "guidance/example-manual-title"

  @originally_published_at = DateTime.parse("14-Dec-#{Date.today.year - 10} 09:30")

  create_manual(@manual_fields) do
    choose("has previously been published on another website.")
    select_datetime @originally_published_at.iso8601, from: "Its original publication date was"
  end

  @manual = most_recently_created_manual

  step %{a draft document exists for the manual}
end

When(/^I tell the manual to stop using the previously published date as the public date$/) do
  WebMock::RequestRegistry.instance.reset!

  edit_manual_original_publication_date(@manual.title) do
    choose("Change the first published date.")
  end

  step %{I publish the manual}
end

When(/^I update the previously published date to a new one$/) do
  WebMock::RequestRegistry.instance.reset!

  @new_originally_published_at = DateTime.parse("25-Mar-#{Date.today.year - 8} 12:57")

  edit_manual_original_publication_date(@manual.title) do
    select_datetime @new_originally_published_at.to_s, from: "First publication date:"
  end

  step %{I publish the manual}
end

When(/^I update the manual to clear the previously published date$/) do
  WebMock::RequestRegistry.instance.reset!

  edit_manual_original_publication_date(@manual.title) do
    clear_datetime "First publication date:"
  end

  step %{I publish the manual}
end

When(/^I tell the manual to start using the previously published date as the public date$/) do
  WebMock::RequestRegistry.instance.reset!

  edit_manual_original_publication_date(@manual.title) do
    choose("Change the first published and last updated date.")
  end

  step %{I publish the manual}
end

When(/^I publish a minor change to the manual$/) do
  steps %{
    When I edit one of the manual's documents as a minor change
    And I publish the manual
  }
end

When(/^I publish a major change to the manual$/) do
  steps %{
    When I edit one of the manual's documents as a major change
    And I publish the manual
  }
end

Then(/^the manual and its documents are (re|)published with all public timestamps set to the previously published date$/) do |republished|
  how_many_times = (republished == "re" ? 2 : 1)

  check_manual_is_drafted_and_published_with_all_public_timestamps(@manual, @originally_published_at, how_many_times: how_many_times)
  check_manual_document_is_drafted_and_published_with_all_public_timestamps(@document, @originally_published_at, how_many_times: how_many_times)
end

Then(/^the manual and its documents are (re|)published with the first published timestamp set to the previously published date, but not the public updated timestamp$/) do |republished|
  how_many_times = (republished == "re" ? 2 : 1)

  check_manual_is_drafted_and_published_with_first_published_date_only(@manual, @originally_published_at, how_many_times: how_many_times)
  check_manual_document_is_drafted_and_published_with_first_published_date_only(@document, @originally_published_at, how_many_times: how_many_times)
end

Then(/^the manual and its documents are (re|)published with all public timestamps set to the new previously published date$/) do |republished|
  how_many_times = (republished == "re" ? 2 : 1)

  check_manual_is_drafted_and_published_with_all_public_timestamps(@manual, @new_originally_published_at, how_many_times: how_many_times)
  check_manual_document_is_drafted_and_published_with_all_public_timestamps(@document, @new_originally_published_at, how_many_times: how_many_times)
end

Then(/^the manual and its documents are (re|)published with the first published timestamp set to the new published date, but not the public updated timestamp$/) do |republished|
  how_many_times = (republished == "re" ? 2 : 1)

  check_manual_is_drafted_and_published_with_first_published_date_only(@manual, @new_originally_published_at, how_many_times: how_many_times)
  check_manual_document_is_drafted_and_published_with_first_published_date_only(@document, @new_originally_published_at, how_many_times: how_many_times)
end

Then(/^the manual and its documents are (re|)published without any public timestamps$/) do |republished|
  how_many_times = (republished == "re" ? 2 : 1)

  check_manual_is_drafted_and_published_with_no_public_timestamps(@manual, how_many_times: how_many_times)
  check_manual_is_drafted_and_published_with_no_public_timestamps(@document, how_many_times: how_many_times)
end
