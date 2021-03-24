require "gds_api_constants"

When(/^I create a manual$/) do
  @manual_fields = {
    title: "Example Manual Title",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }
  @manual_slug = "guidance/example-manual-title"

  create_manual(@manual_fields)

  @manual = most_recently_created_manual
end

Then(/^the manual should exist$/) do
  check_manual_exists_with(@manual_fields)
end

Then(/^I should see a link to preview the manual$/) do
  check_content_preview_link(@manual_slug)
end

Then(/^the manual should have been sent to the draft publishing api$/) do
  check_manual_is_drafted_to_publishing_api(@manual.id)
end

Then(/^the edited manual should have been sent to the draft publishing api$/) do
  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    extra_attributes: { title: @new_title },
  )
end

Given(/^a draft manual exists without any sections$/) do
  @manual_slug = "guidance/example-manual-title"
  @manual_title = "Example Manual Title"

  @manual_fields = {
    title: "Example Manual Title",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }

  create_manual(@manual_fields)

  @manual = most_recently_created_manual

  WebMock::RequestRegistry.instance.reset!
end

Given(/^a draft manual exists with some sections$/) do
  @manual_slug = "guidance/example-manual-title"
  @manual_title = "Example Manual Title"

  @manual_fields = {
    title: "Example Manual Title",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }

  create_manual(@manual_fields)

  @attributes_for_sections = create_sections_for_manual(
    manual_fields: @manual_fields,
    count: 2,
  )

  @manual = most_recently_created_manual
  @sections = @manual.sections.to_a
  @section = @sections.first

  WebMock::RequestRegistry.instance.reset!
end

Given(/^a draft manual exists belonging to "(.*?)"$/) do |organisation_slug|
  @manual_slug = "guidance/example-manual-title"
  @manual_title = "Example Manual Title"

  @manual_fields = {
    title: "Example Manual Title",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }

  stub_organisation_details(organisation_slug)
  @manual = create_manual_without_ui(@manual_fields, organisation_slug: organisation_slug)
  WebMock::RequestRegistry.instance.reset!
end

When(/^I edit (?:a|the) manual$/) do
  @new_title = "Edited Example Manual"
  edit_manual(@manual_fields[:title], title: @new_title)
  @manual = most_recently_created_manual
end

Then(/^the manual should have been updated$/) do
  check_manual_exists_with(@manual_fields.merge(title: @new_title))
end

When(/^I create a manual with an empty title$/) do
  @manual_fields = {
    title: "",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }

  create_manual(@manual_fields)
end

Then(/^I see errors for the title field$/) do
  check_for_errors_for_fields("title")
end

When(/^I create a section for the manual$/) do
  @section_title = "Created Section 1"
  @section_slug = [@manual_slug, "created-section-1"].join("/")

  @section_fields = {
    section_title: @section_title,
    section_summary: "Section 1 summary",
    section_body: "Section 1 body",
  }

  create_section(@manual_fields.fetch(:title), @section_fields)

  @section = most_recently_created_manual.sections.to_a.last
end

When(/^I create an expanded section for the manual$/) do
  @section_title = "Created Section 1"
  @section_slug = [@manual_slug, "created-section-1"].join("/")

  @section_fields = {
    section_title: @section_title,
    section_summary: "Section 1 summary",
    section_body: "Section 1 body",
  }

  create_expanded_section(@manual_fields.fetch(:title), @section_fields)

  @section = most_recently_created_manual.sections.to_a.last
end

When(/^I create a section for the manual with a change note$/) do
  @section_title = "Created Section 1"
  @section_slug = [@manual_slug, "created-section-1"].join("/")

  @change_note = "Adding a brand new exciting section"
  @section_fields = {
    section_title: @section_title,
    section_summary: "Section 1 summary",
    section_body: "Section 1 body",
    change_note: @change_note,
  }

  create_section(@manual_fields.fetch(:title), @section_fields)

  @section = most_recently_created_manual.sections.to_a.last
end

Then(/^I see the manual has the new section$/) do
  visit manuals_path
  click_on @manual_fields.fetch(:title)
  expect(page).to have_content(@section_fields.fetch(:section_title))
end

Then(/^I see the section isn't visually expanded$/) do
  click_on @section_fields.fetch(:section_title)
  expect(@section.visually_expanded).to eq(false)
end

Then(/^I see the section is visually expanded$/) do
  click_on @section_fields.fetch(:section_title)
  expect(@section.visually_expanded).to eq(true)
end

Then(/^the section and table of contents will have been sent to the draft publishing api$/) do
  check_section_is_drafted_to_publishing_api(@section.uuid)
  manual_table_of_contents_attributes = {
    details: {
      child_section_groups: [
        {
          title: GdsApiConstants::PublishingApi::CHILD_SECTION_GROUP_TITLE,
          child_sections: [
            {
              title: @section_title,
              description: @section_fields[:section_summary],
              base_path: "/#{@section_slug}",
            },
          ],
        },
      ],
    },
  }
  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    extra_attributes: manual_table_of_contents_attributes,
  )
end

Then(/^the updated section at the new slug and updated table of contents will have been sent to the draft publishing api$/) do
  check_section_is_drafted_to_publishing_api(@section.uuid)
  manual_table_of_contents_attributes = {
    details: {
      child_section_groups: [
        {
          title: GdsApiConstants::PublishingApi::CHILD_SECTION_GROUP_TITLE,
          child_sections: [
            {
              title: @new_title,
              description: @section_fields[:section_summary],
              base_path: "/#{@new_slug}",
            },
          ],
        },
      ],
    },
  }
  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    extra_attributes: manual_table_of_contents_attributes,
  )
end

Given(/^a draft section exists for the manual$/) do
  @section_title = "New section"
  @section_slug = "guidance/example-manual-title/new-section"

  @section_fields = {
    section_title: @section_title,
    section_summary: "New section summary",
    section_body: "New section body",
  }

  create_section(@manual_fields.fetch(:title), @section_fields)

  @section = most_recently_created_manual.sections.to_a.last

  @sections ||= []
  @sections << @section

  WebMock::RequestRegistry.instance.reset!
end

When(/^I edit the section$/) do
  @new_title = "A new section title"
  @new_slug = "#{@manual_slug}/a-new-section-title"
  edit_section(
    @manual_fields.fetch(:title),
    @section_fields.fetch(:section_title),
    section_title: @new_title,
  )
end

Then(/^the section should have been updated$/) do
  check_section_exists_with(
    @manual_fields.fetch(:title),
    section_title: @new_title,
  )
end

Then(/^the manual's sections won't have changed$/) do
  expect(page).to have_content(@section_fields.fetch(:section_title))
end

When(/^I create a section with empty fields$/) do
  create_section(@manual_fields.fetch(:title), {})
end

Then(/^I see errors for the section fields$/) do
  %w[Title Summary Body].each do |field|
    expect(page).to have_content("#{field} can't be blank")
  end
  expect(page).not_to have_content("Add attachment")
end

When(/^I publish the manual$/) do
  go_to_manual_page(@manual.title) if current_path != manual_path(@manual)
  publish_manual
end

When(/^I add another section and publish the manual later$/) do
  create_section(
    @manual.title,
    section_title: "Another section so we can publish",
    section_summary: "Another section so we can publish summary",
    section_body: "Another section so we can publish body",
  )
  go_to_manual_page(@manual.title)
  publish_manual
end

Then(/^the manual and all its sections are published$/) do
  @sections.each do |section|
    check_manual_and_sections_were_published(
      @manual,
      section,
      @manual_fields,
      section_fields(section),
    )
  end
end

Then(/^the manual and the edited section are published$/) do
  check_manual_and_sections_were_published(
    @manual, @updated_section, @manual_fields, @updated_fields
  )
end

Then(/^the updated section is available to preview$/) do
  check_section_is_drafted_to_publishing_api(@updated_section.uuid)
  sections = @sections.map do |section|
    {
      title: section == @updated_section ? @updated_fields[:section_title] : section.title,
      description: section == @updated_section ? @updated_fields[:section_summary] : section.summary,
      base_path: "/#{section.slug}",
    }
  end
  manual_table_of_contents_attributes = {
    details: {
      child_section_groups: [
        {
          title: GdsApiConstants::PublishingApi::CHILD_SECTION_GROUP_TITLE,
          child_sections: sections,
        },
      ],
    },
  }
  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    extra_attributes: manual_table_of_contents_attributes,
  )
end

Then(/^the sections that I didn't edit were not republished$/) do
  @sections.reject { |s| s.uuid == @updated_section.uuid }.each do |section|
    check_section_was_not_published(section)
  end
end

Then(/^the manual and its new section are published$/) do
  check_manual_and_sections_were_published(
    @manual,
    @new_section,
    @manual_fields,
    section_fields(@new_section),
  )
end

Then(/^I should see a link to the live manual$/) do
  check_live_link(@manual_slug)
end

Given(/^a published manual exists$/) do
  @manual_title = "Example Manual Title"
  @manual_slug = "guidance/example-manual-title"

  @manual_fields = {
    title: @manual_title,
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }

  create_manual(@manual_fields)

  create_sections_for_manual(
    manual_fields: @manual_fields,
    count: 2,
  )

  @manual = most_recently_created_manual
  @sections = @manual.sections.to_a

  publish_manual

  WebMock::RequestRegistry.instance.reset!
end

Given(/^a published manual with some sections was created without the UI$/) do
  @manual_title = "Example Manual Title"
  @manual_slug = "guidance/example-manual-title"

  @manual_fields = { title: @manual_title,
                     summary: "Nullam quis risus eget urna mollis ornare vel eu leo." }

  @manual = create_manual_without_ui(@manual_fields, organisation_slug: GDS::SSO.test_user.organisation_slug)

  sec1 = create_section_without_ui(
    @manual,
    {
      title: "1st example section",
      summary: "1st example section summary",
      body: "1st example section body",
    },
    organisation_slug: GDS::SSO.test_user.organisation_slug,
  )
  sec2 = create_section_without_ui(
    @manual,
    {
      title: "2nd example section",
      summary: "2nd example section summary",
      body: "2nd example section body",
    },
    organisation_slug: GDS::SSO.test_user.organisation_slug,
  )
  @sections = [sec1, sec2]

  publish_manual_without_ui(@manual)

  WebMock::RequestRegistry.instance.reset!
end

When(/^I create a section for the manual as a minor change without the UI$/) do
  @section_title = "Created Section 1"
  @section_slug = [@manual_slug, "created-section-1"].join("/")

  @section_fields = {
    title: @section_title,
    summary: "Section 1 summary",
    body: "Section 1 body",
    minor_update: true,
  }

  @section = create_section_without_ui(@manual, @section_fields, organisation_slug: GDS::SSO.test_user.organisation_slug)

  go_to_manual_page(@manual.title)

  WebMock::RequestRegistry.instance.reset!
end

When(/^I edit one of the manual's sections(?: as a major change)?$/) do
  WebMock::RequestRegistry.instance.reset!
  @updated_section = @sections.first

  @updated_fields = {
    section_title: @updated_section.title,
    section_summary: "Updated section",
    section_body: "Updated section",
    change_note: "Updated section",
  }

  edit_section(@manual_title || @manual.title, @updated_section.title, @updated_fields) do
    choose("Major update")
  end
end

When(/^I edit one of the manual's sections without a change note$/) do
  WebMock::RequestRegistry.instance.reset!
  @updated_section = @sections.first

  @updated_fields = {
    section_title: @updated_section.title,
    section_summary: "Updated section",
    section_body: "Updated section",
    change_note: "",
  }

  edit_section(@manual_title || @manual.title, @updated_section.title, @updated_fields) do
    choose("Major update")
  end
end

When(/^I edit one of the manual's sections as a minor change$/) do
  WebMock::RequestRegistry.instance.reset!
  @updated_section = @sections.first

  @updated_fields = {
    section_title: @updated_section.title,
    section_summary: "Updated section",
    section_body: "Updated section",
  }

  edit_section(@manual_title || @manual.title, @updated_section.title, @updated_fields) do
    choose("Minor update")
  end
end

When(/^I preview the section$/) do
  click_button("Preview")
end

When(/^I create a section to preview$/) do
  @section_fields = {
    section_title: "Section 1",
    section_summary: "Section 1 summary",
    section_body: "Section 1 body",
  }

  go_to_manual_page(@manual_fields[:title])
  click_on "Add section"
  fill_in_fields(@section_fields)
end

Then(/^I see the section body preview$/) do
  check_for_document_body_preview("Section 1 body")
end

When(/^I copy\+paste the embed code into the body of the section$/) do
  copy_embed_code_for_attachment_and_paste_into_section_body("My attachment")
end

Then(/^I see an error requesting that I provide a change note$/) do
  expect(page).to have_content("You must provide a change note or indicate minor update")
end

When(/^I indicate that the change is minor$/) do
  choose("Minor update")
  click_on "Save as draft"
end

Then(/^the section is updated without a change note$/) do
  check_section_exists_with(
    @manual_title,
    section_title: @updated_section.title,
    section_summary: @updated_fields[:section_summary],
  )
end

Then(/^the manual is published as a major update including a change note draft$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_manual_is_drafted_to_publishing_api(@manual.id, extra_attributes: { update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE }, number_of_drafts: 2)
end

Then(/^the manual is published as a minor update including a change note draft$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_manual_is_drafted_to_publishing_api(@manual.id, extra_attributes: { update_type: GdsApiConstants::PublishingApi::MINOR_UPDATE_TYPE }, number_of_drafts: 2)
end

Then(/^the manual is published as a major update$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_manual_is_drafted_to_publishing_api(@manual.id, extra_attributes: { update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE }, number_of_drafts: 1)
end

Then(/^the section is published as a major update including a change note draft$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_section_is_drafted_to_publishing_api((@updated_section || @section).uuid, extra_attributes: { update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE }, number_of_drafts: 2)
end

Then(/^the section is published as a major update$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_section_is_drafted_to_publishing_api((@updated_section || @section).uuid, extra_attributes: { update_type: GdsApiConstants::PublishingApi::MAJOR_UPDATE_TYPE }, number_of_drafts: 1)
end

Then(/^the section is published as a minor update including a change note draft$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_section_is_drafted_to_publishing_api((@updated_section || @section).uuid, extra_attributes: { update_type: GdsApiConstants::PublishingApi::MINOR_UPDATE_TYPE }, number_of_drafts: 2)
end

Then(/^I can see the change note and update type form when editing existing sections$/) do
  @sections.each do |section|
    go_to_manual_page(@manual.title)
    click_on section.title
    click_on "Edit section"

    check_that_change_note_fields_are_present
  end
end

Then(/^I can see the change note form when adding a new section$/) do
  go_to_manual_page(@manual.title)
  click_on "Add section"

  check_that_change_note_fields_are_present(note_field_only: true, note: "New section added.")
end

Then(/^the change note form for the section is clear$/) do
  go_to_manual_page(@manual.title)
  click_on((@updated_section || @section).title)
  click_on "Edit section"

  check_that_change_note_fields_are_present(minor_update: false, note: "")
end

Then(/^the change note form for the section contains my note$/) do
  go_to_manual_page(@manual.title)
  click_on((@updated_section || @section).title)
  click_on "Edit section"

  check_that_change_note_fields_are_present(note_field_only: true, note: @change_note)
end

When(/^I add another section to the manual$/) do
  title = "Section 2"

  fields = {
    section_title: title,
    section_summary: "#{title} summary",
    section_body: "#{title} body",
  }

  create_section(@manual_title, fields)

  @new_section = most_recently_created_manual.sections.to_a.last
end

Then(/^I see no visible change note in the section edit form$/) do
  section = @sections.first
  check_change_note_value(@manual_title, section.title, "")
end

When(/^I add invalid HTML to the section body$/) do
  fill_in :body, with: "<script>alert('naughty naughty');</script>"
end

When(/^I create another manual with the same slug$/) do
  create_manual(@manual_fields)
end

When(/^I create a section with duplicate title$/) do
  create_section(@manual_fields.fetch(:title), @section_fields)
end

Then(/^the manual and its sections have failed to publish$/) do
  expect(page).to have_content("This manual was sent for publishing")
  expect(page).to have_content("something went wrong. Our team has been notified.")
end

Then(/^the manual and its sections are queued for publishing$/) do
  expect(page).to have_content("This manual was sent for publishing")
  expect(page).to have_content("It should be published shortly.")
end

Given(/^a recoverable error occurs$/) do
  stub_http_server_error
end

Given(/^an unrecoverable error occurs$/) do
  stub_http_error_response
end

Given(/^a version mismatch occurs$/) do
  Manual::PublishService.any_instance.stub(:call)
    .and_raise(Manual::PublishService::VersionMismatchError.new)
end

When(/^I publish the manual expecting a recoverable error$/) do
  publish_manual
rescue PublishManualWorker::FailedToPublishError => e
  @error = e
end

Then(/^the publication reattempted$/) do
  # This is merely to assure that the correct error type is raised forcing
  # sidekiq to retry. This is the default behaviour of sidekiq in the case of a failure
  expect(@error).to be_a(PublishManualWorker::FailedToPublishError)
end

When(/^I make changes and preview the manual$/) do
  change_manual_without_saving(
    @manual_title,
    title: "Title for preview",
    body: "Body for preview",
  )
  click_button("Preview")
end

When(/^I start creating a new manual$/) do
  @manual_title = "Original Manual title"

  @manual_fields = {
    title: @manual_title,
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
    body: "Body for preview",
  }

  create_manual(@manual_fields, save: false)
end

When(/^I preview the manual$/) do
  click_button("Preview")
end

Then(/^I see the manual body preview$/) do
  check_for_manual_body_preview
end

When(/^I start creating a new manual with embedded javascript$/) do
  @manual_fields = {
    body: "<script>alert('Oh noes!)</script>",
  }

  create_manual(@manual_fields, save: false)
end

Then(/^I see a warning about section slug clash at publication$/) do
  check_for_clashing_section_slugs
end

When(/^a DevOps specialist withdraws the manual for me$/) do
  withdraw_manual_without_ui(@manual)
end

Then(/^the manual should be withdrawn$/) do
  check_manual_is_withdrawn(@manual, @sections)
end

Then(/^the manual should belong to "(.*?)"$/) do |organisation_slug|
  check_manual_has_organisation_slug(@manual_fields, organisation_slug)
end

Then(/^the manual should still belong to "(.*?)"$/) do |organisation_slug|
  check_manual_has_organisation_slug(@manual_fields.merge(title: @new_title), organisation_slug)
end

When(/^I reorder the sections$/) do
  click_on("Reorder sections")
  elems = page.all(".reorderable-document-list li.ui-sortable-handle")
  elems[0].drag_to(elems[1])
  click_on("Save section order")
  @reordered_section_attributes = [
    @attributes_for_sections[1],
    @attributes_for_sections[0],
  ]
end

Then(/^the order of the sections in the manual should have been updated$/) do
  @reordered_section_attributes.map { |sec| sec[:title] }.each.with_index do |title, index|
    expect(page).to have_css(".document-list li.document:nth-child(#{index + 1}) .document-title", text: title)
  end
end

Then(/^the new order should be visible in the preview environment$/) do
  manual_table_of_contents_attributes = {
    details: {
      child_section_groups: [
        {
          title: GdsApiConstants::PublishingApi::CHILD_SECTION_GROUP_TITLE,
          child_sections: @reordered_section_attributes.map do |sec|
            {
              title: sec[:fields][:section_title],
              description: sec[:fields][:section_summary],
              base_path: "/#{sec[:slug]}",
            }
          end,
        },
      ],
    },
  }
  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    extra_attributes: manual_table_of_contents_attributes,
  )
end

Then(/^the manual is listed as (draft|published|published with new draft)$/) do |status|
  visit manuals_path

  expect(page).to have_selector(:xpath, "//li[a[.='#{@manual.title}']]//span[contains(concat(' ', normalize-space(@class), ' '), ' label ')][.='#{status}']")

  click_on @manual.title

  expect(page).to have_selector(:xpath, "//dt[.='State']/following-sibling::dd[.='#{status}']")
end
