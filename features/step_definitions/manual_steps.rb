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

  @attributes_for_documents = create_documents_for_manual(
    manual_fields: @manual_fields,
    count: 2,
  )

  @manual = most_recently_created_manual
  @documents = @manual.sections.to_a
  @document = @documents.first

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
  @document_title = "Created Section 1"
  @document_slug = [@manual_slug, "created-section-1"].join("/")

  @document_fields = {
    section_title: @document_title,
    section_summary: "Section 1 summary",
    section_body: "Section 1 body",
  }

  create_section(@manual_fields.fetch(:title), @document_fields)

  @document = most_recently_created_manual.sections.to_a.last
end

When(/^I create a section for the manual with a change note$/) do
  @document_title = "Created Section 1"
  @document_slug = [@manual_slug, "created-section-1"].join("/")

  @change_note = "Adding a brand new exciting section"
  @document_fields = {
    section_title: @document_title,
    section_summary: "Section 1 summary",
    section_body: "Section 1 body",
    change_note: @change_note
  }

  create_section(@manual_fields.fetch(:title), @document_fields)

  @document = most_recently_created_manual.sections.to_a.last
end

Then(/^I see the manual has the new section$/) do
  visit manuals_path
  click_on @manual_fields.fetch(:title)
  expect(page).to have_content(@document_fields.fetch(:section_title))
end

Then(/^the section and table of contents will have been sent to the draft publishing api$/) do
  check_section_is_drafted_to_publishing_api(@document.id)
  manual_table_of_contents_attributes = {
    details: {
      child_section_groups: [
        {
          title: "Contents",
          child_sections: [
            {
              title: @document_title,
              description: @document_fields[:section_summary],
              base_path: "/#{@document_slug}",
            }
          ]
        }
      ]
    }
  }
  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    extra_attributes: manual_table_of_contents_attributes,
  )
end

Then(/^the updated section at the new slug and updated table of contents will have been sent to the draft publishing api$/) do
  check_section_is_drafted_to_publishing_api(@document.id)
  manual_table_of_contents_attributes = {
    details: {
      child_section_groups: [
        {
          title: "Contents",
          child_sections: [
            {
              title: @new_title,
              description: @document_fields[:section_summary],
              base_path: "/#{@new_slug}",
            }
          ]
        }
      ]
    }
  }
  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    extra_attributes: manual_table_of_contents_attributes,
  )
end

Given(/^a draft section exists for the manual$/) do
  @document_title = "New section"
  @document_slug = "guidance/example-manual-title/new-section"

  @document_fields = {
    section_title: @document_title,
    section_summary: "New section summary",
    section_body: "New section body",
  }

  create_section(@manual_fields.fetch(:title), @document_fields)

  @document = most_recently_created_manual.sections.to_a.last

  @documents ||= []
  @documents << @document

  WebMock::RequestRegistry.instance.reset!
end

When(/^I edit the section$/) do
  @new_title = "A new section title"
  @new_slug = "#{@manual_slug}/a-new-section-title"
  edit_section(
    @manual_fields.fetch(:title),
    @document_fields.fetch(:section_title),
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
  expect(page).to have_content(@document_fields.fetch(:section_title))
end

When(/^I create a section with empty fields$/) do
  create_section(@manual_fields.fetch(:title), {})
end

Then(/^I see errors for the section fields$/) do
  %w(Title Summary Body).each do |field|
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
    section_body: "Another section so we can publish body"
  )
  go_to_manual_page(@manual.title)
  publish_manual
end

Then(/^the manual and all its sections are published$/) do
  @documents.each do |document|
    check_manual_and_sections_were_published(
      @manual,
      document,
      @manual_fields,
      document_fields(document),
    )
  end
end

Then(/^the manual and the edited section are published$/) do
  check_manual_and_sections_were_published(
    @manual, @updated_document, @manual_fields, @updated_fields
  )
end

Then(/^the updated section is available to preview$/) do
  check_section_is_drafted_to_publishing_api(@updated_document.id)
  sections = @documents.map do |document|
    {
      title: document == @updated_document ? @updated_fields[:section_title] : document.title,
      description: document == @updated_document ? @updated_fields[:section_summary] : document.summary,
      base_path: "/#{document.slug}",
    }
  end
  manual_table_of_contents_attributes = {
    details: {
      child_section_groups: [
        {
          title: "Contents",
          child_sections: sections,
        }
      ]
    }
  }
  check_manual_is_drafted_to_publishing_api(
    @manual.id,
    extra_attributes: manual_table_of_contents_attributes,
  )
end

Then(/^the sections that I didn't edit were not republished$/) do
  @documents.reject { |d| d.id == @updated_document.id }.each do |document|
    check_section_was_not_published(document)
  end
end

Then(/^the manual and its new section are published$/) do
  check_manual_and_sections_were_published(
    @manual,
    @new_document,
    @manual_fields,
    document_fields(@new_document),
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

  create_documents_for_manual(
    manual_fields: @manual_fields,
    count: 2,
  )

  @manual = most_recently_created_manual
  @documents = @manual.sections.to_a

  publish_manual

  WebMock::RequestRegistry.instance.reset!
end

Given(/^a published manual with some sections was created without the UI$/) do
  @manual_title = "Example Manual Title"
  @manual_slug = "guidance/example-manual-title"

  @manual_fields = {
    title: @manual_title,
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }

  @manual = create_manual_without_ui(@manual_fields, organisation_slug: GDS::SSO.test_user.organisation_slug)

  doc_1 = create_section_without_ui(
    @manual,
    {
      title: "1st example section",
      summary: "1st example section summary",
      body: "1st example section body"
    },
    organisation_slug: GDS::SSO.test_user.organisation_slug
  )
  doc_2 = create_section_without_ui(
    @manual,
    {
      title: "2nd example section",
      summary: "2nd example section summary",
      body: "2nd example section body"
    },
    organisation_slug: GDS::SSO.test_user.organisation_slug
  )
  @documents = [doc_1, doc_2]

  publish_manual_without_ui(@manual)

  WebMock::RequestRegistry.instance.reset!
end

When(/^I create a section for the manual as a minor change without the UI$/) do
  @document_title = "Created Section 1"
  @document_slug = [@manual_slug, "created-section-1"].join("/")

  @document_fields = {
    title: @document_title,
    summary: "Section 1 summary",
    body: "Section 1 body",
    minor_update: true
  }

  @document = create_section_without_ui(@manual, @document_fields, organisation_slug: GDS::SSO.test_user.organisation_slug)

  go_to_manual_page(@manual.title)

  WebMock::RequestRegistry.instance.reset!
end

When(/^I edit one of the manual's sections(?: as a major change)?$/) do
  WebMock::RequestRegistry.instance.reset!
  @updated_document = @documents.first

  @updated_fields = {
    section_title: @updated_document.title,
    section_summary: "Updated section",
    section_body: "Updated section",
    change_note: "Updated section",
  }

  edit_section(@manual_title || @manual.title, @updated_document.title, @updated_fields) do
    choose("Major update")
  end
end

When(/^I edit one of the manual's sections without a change note$/) do
  WebMock::RequestRegistry.instance.reset!
  @updated_document = @documents.first

  @updated_fields = {
    section_title: @updated_document.title,
    section_summary: "Updated section",
    section_body: "Updated section",
    change_note: "",
  }

  edit_section(@manual_title || @manual.title, @updated_document.title, @updated_fields) do
    choose("Major update")
  end
end

When(/^I edit one of the manual's sections as a minor change$/) do
  WebMock::RequestRegistry.instance.reset!
  @updated_document = @documents.first

  @updated_fields = {
    section_title: @updated_document.title,
    section_summary: "Updated section",
    section_body: "Updated section",
  }

  edit_section(@manual_title || @manual.title, @updated_document.title, @updated_fields) do
    choose("Minor update")
  end
end

When(/^I preview the section$/) do
  generate_preview
end

When(/^I create a section to preview$/) do
  @document_fields = {
    section_title: "Section 1",
    section_summary: "Section 1 summary",
    section_body: "Section 1 body",
  }

  go_to_manual_page(@manual_fields[:title])
  click_on "Add section"
  fill_in_fields(@document_fields)
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
  save_document
end

Then(/^the section is updated without a change note$/) do
  check_section_exists_with(
    @manual_title,
    section_title: @updated_document.title,
    section_summary: @updated_fields[:section_summary],
  )
end

Then(/^the manual is published as a major update including a change note draft$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_manual_is_drafted_to_publishing_api(@manual.id, extra_attributes: { update_type: "major" }, number_of_drafts: 2)
end

Then(/^the manual is published as a minor update including a change note draft$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_manual_is_drafted_to_publishing_api(@manual.id, extra_attributes: { update_type: "minor" }, number_of_drafts: 2)
end

Then(/^the manual is published as a major update$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_manual_is_drafted_to_publishing_api(@manual.id, extra_attributes: { update_type: "major" }, number_of_drafts: 1)
end

Then(/^the section is published as a major update including a change note draft$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_section_is_drafted_to_publishing_api((@updated_document || @document).id, extra_attributes: { update_type: "major" }, number_of_drafts: 2)
end

Then(/^the section is published as a major update$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_section_is_drafted_to_publishing_api((@updated_document || @document).id, extra_attributes: { update_type: "major" }, number_of_drafts: 1)
end

Then(/^the section is published as a minor update including a change note draft$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_section_is_drafted_to_publishing_api((@updated_document || @document).id, extra_attributes: { update_type: "minor" }, number_of_drafts: 2)
end

Then(/^I can see the change note and update type form when editing existing sections$/) do
  @documents.each do |document|
    go_to_manual_page(@manual.title)
    click_on document.title
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
  click_on((@updated_document || @document).title)
  click_on "Edit section"

  check_that_change_note_fields_are_present(minor_update: false, note: "")
end

Then(/^the change note form for the section contains my note$/) do
  go_to_manual_page(@manual.title)
  click_on((@updated_document || @document).title)
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

  @new_document = most_recently_created_manual.sections.to_a.last
end

Then(/^I see no visible change note in the section edit form$/) do
  document = @documents.first
  check_change_note_value(@manual_title, document.title, "")
end

When(/^I add invalid HTML to the section body$/) do
  fill_in :body, with: "<script>alert('naughty naughty');</script>"
end

When(/^I create another manual with the same slug$/) do
  create_manual(@manual_fields)
end

When(/^I create a section with duplicate title$/) do
  create_section(@manual_fields.fetch(:title), @document_fields)
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
  mock_rummager_http_server_error
end

Given(/^an unrecoverable error occurs$/) do
  mock_rummager_http_client_error
end

Given(/^a version mismatch occurs$/) do
  PublishManualService.any_instance.stub(:versions_match?).and_return(false)
end

When(/^I publish the manual expecting a recoverable error$/) do
  begin
    publish_manual
  rescue PublishManualWorker::FailedToPublishError => e
    @error = e
  end
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
  generate_preview
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
  generate_preview
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
  check_manual_is_withdrawn(@manual, @documents)
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
  @reordered_document_attributes = [
    @attributes_for_documents[1],
    @attributes_for_documents[0]
  ]
end

Then(/^the order of the sections in the manual should have been updated$/) do
  @reordered_document_attributes.map { |doc| doc[:title] }.each.with_index do |title, index|
    expect(page).to have_css(".document-list li.document:nth-child(#{index + 1}) .document-title", text: title)
  end
end

Then(/^the new order should be visible in the preview environment$/) do
  manual_table_of_contents_attributes = {
    details: {
      child_section_groups: [
        {
          title: "Contents",
          child_sections: @reordered_document_attributes.map do |doc|
            {
              title: doc[:fields][:section_title],
              description: doc[:fields][:section_summary],
              base_path: "/#{doc[:slug]}",
            }
          end
        }
      ]
    }
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
