Given(/^I create a manual that was previously published elsewhere$/) do
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
end

Then(/^the manual is published with first published at and public updated at dates set to the previously published date$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    extra_attributes: {
      first_published_at: @originally_published_at.iso8601,
      public_updated_at: @originally_published_at.iso8601,
    },
    number_of_drafts: 1
  )
  check_manual_was_published(@manual)
end

Then(/^the document is published with first published at and public updated at dates set to the previously published date$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_manual_document_is_drafted_to_publishing_api(
    @document.id,
    extra_attributes: {
      first_published_at: @originally_published_at.iso8601,
      public_updated_at: @originally_published_at.iso8601,
    },
    number_of_drafts: 1
  )
  check_manual_document_was_published(@document)
end
