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
    extra_attributes: {title: @new_title},
  )
end

Given(/^a draft manual exists without any documents$/) do
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

Given(/^a draft manual exists with some documents$/) do
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
  @documents = @manual.documents.to_a
  @document = @documents.first

  WebMock::RequestRegistry.instance.reset!
end

Given(/^a draft manual was created without the UI$/) do
  @manual_slug = "guidance/example-manual-title"
  @manual_title = "Example Manual Title"

  @manual_fields = {
    title: "Example Manual Title",
    summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
  }

  @manual = create_manual_without_ui(@manual_fields)
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

When(/^I edit a manual$/) do
  @new_title = "Edited Example Manual"
  edit_manual(@manual_fields[:title], title: @new_title)
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

When(/^I create a document for the manual$/) do
  @document_title = "Created Section 1"
  @document_slug = [@manual_slug, "created-section-1"].join("/")

  @document_fields = {
    section_title: @document_title,
    section_summary: "Section 1 summary",
    section_body: "Section 1 body",
  }

  create_manual_document(@manual_fields.fetch(:title), @document_fields)

  @document = most_recently_created_manual.documents.to_a.last
end

Then(/^I see the manual has the new section$/) do
  visit manuals_path
  click_on @manual_fields.fetch(:title)
  expect(page).to have_content(@document_fields.fetch(:section_title))
end

Then(/^the manual document and table of contents will have been sent to the draft publishing api$/) do
  check_manual_document_is_drafted_to_publishing_api(@document.id)
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

Then(/^the updated manual document at the new slug and updated table of contents will have been sent to the draft publishing api$/) do
  check_manual_document_is_drafted_to_publishing_api(@document.id)
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

Given(/^a draft document exists for the manual$/) do
  @document_title = "New section"
  @document_slug = "guidance/example-manual-title/new-section"

  @document_fields = {
    section_title: @document_title,
    section_summary: "New section summary",
    section_body: "New section body",
  }

  create_manual_document(@manual_fields.fetch(:title), @document_fields)

  @document = most_recently_created_manual.documents.to_a.last

  WebMock::RequestRegistry.instance.reset!
end

Given(/^a draft section was created for the manual without the UI$/) do
  @document_title = "New section"
  @document_slug = "guidance/example-manual-title/new-section"

  @document_fields = {
    title: @document_title,
    summary: "New section summary",
    body: "New section body",
  }

  @section = create_manual_document_without_ui(@manual, @document_fields)
  WebMock::RequestRegistry.instance.reset!
end

When(/^I edit the document$/) do
  @new_title = "A new section title"
  @new_slug = "#{@manual_slug}/a-new-section-title"
  edit_manual_document(
    @manual_fields.fetch(:title),
    @document_fields.fetch(:section_title),
    section_title: @new_title,
  )
end

Then(/^the document should have been updated$/) do
  check_manual_document_exists_with(
    @manual_fields.fetch(:title),
    section_title: @new_title,
  )
end

When(/^I visit the specialist documents path for the manual document$/) do
  link = page.find("a", text: @document_title)
  document_id = URI.parse(link["href"]).path.split("/").last
  visit cma_case_path(document_id)
end

Then(/^the document is not found$/) do
  expect(page).to have_content("Document not found")
end

Then(/^the manual's documents won't have changed$/) do
  expect(page).to have_content(@document_fields.fetch(:section_title))
end

When(/^I create a document with empty fields$/) do
  create_manual_document(@manual_fields.fetch(:title), {})
end

Then(/^I see errors for the document fields$/) do
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
  create_manual_document(@manual.title, {
    section_title: "Another section so we can publish",
    section_summary: "Another section so we can publish summary",
    section_body: "Another section so we can publish body",
  })
  go_to_manual_page(@manual.title)
  publish_manual
end

Then(/^the manual and all its documents are published$/) do
  @documents.each do |document|
    check_manual_and_documents_were_published(
      @manual,
      document,
      @manual_fields,
      document_fields(document),
    )
  end
end

Then(/^the manual and the edited document are published$/) do
  check_manual_and_documents_were_published(
    @manual, @updated_document, @manual_fields, @updated_fields
  )
end

Then(/^the updated manual document is available to preview$/) do
  check_manual_document_is_drafted_to_publishing_api(@updated_document.id)
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

Then(/^the manual documents that I didn't edit were not republished$/) do
  @documents.reject { |d| d.id == @updated_document.id }.each do |document|
    check_manual_document_was_not_published(document)
  end
end

Then(/^the manual and its new document are published$/) do
  check_manual_and_documents_were_published(
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
  @documents = @manual.documents.to_a

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

  doc_1 = create_manual_document_without_ui(
    @manual,
    {
      title: "1st example section",
      summary: "1st example section summary",
      body: "1st example section body"
    },
    organisation_slug: GDS::SSO.test_user.organisation_slug
  )
  doc_2 = create_manual_document_without_ui(
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

When(/^I edit one of the manual's documents$/) do
  WebMock::RequestRegistry.instance.reset!
  @updated_document = @documents.first

  @updated_fields = {
    section_title: @updated_document.title,
    section_summary: "Updated section",
    section_body: "Updated section",
    change_note: "Updated section",
  }

  edit_manual_document(@manual_title, @updated_document.title, @updated_fields)
end

When(/^I edit one of the manual's documents without a change note$/) do
  WebMock::RequestRegistry.instance.reset!
  @updated_document = @documents.first

  @updated_fields = {
    section_title: @updated_document.title,
    section_summary: "Updated section",
    section_body: "Updated section",
    change_note: "",
  }

  edit_manual_document(@manual_title, @updated_document.title, @updated_fields)
end

When(/^I start creating a new manual document$/) do
  @document_fields = {
    section_title: "Section 1",
    section_summary: "Section 1 summary",
    section_body: "Section 1 body",
  }

  create_manual_document_for_preview(
    @document_fields.fetch(:title),
    @document_fields,
  )
end

When(/^I preview the document$/) do
  generate_preview
end

When(/^I create a document to preview$/) do
  @document_fields = {
    section_title: "Section 1",
    section_summary: "Section 1 summary",
    section_body: "Section 1 body",
  }

  go_to_manual_page(@manual_fields[:title])
  click_on "Add section"
  fill_in_fields(@document_fields)
end

Then(/^I see the document body preview$/) do
  check_for_document_body_preview("Section 1 body")
end

When(/^I copy\+paste the embed code into the body of the document$/) do
  copy_embed_code_for_attachment_and_paste_into_manual_document_body("My attachment")
end

When(/^I create a new draft of a section with a change note$/) do
  document = @documents.first

  click_on(document.title)
  click_on("Edit section")

  @change_note = "Changed title for the purposes of testing."

  fields = {
    section_title: "This document has changed for the purposes of testing",
    change_note: @change_note,
  }

  save_document
  edit_manual_document(@manual_title, document.title, fields)
end

Then(/^I see an error requesting that I provide a change note$/) do
  expect(page).to have_content("You must provide a change note or indicate minor update")
end

When(/^I indicate that the change is minor$/) do
  check("Minor update")
  save_document
end

Then(/^the document is updated without a change note$/) do
  check_manual_document_exists_with(
    @manual_title,
    section_title: @updated_document.title,
    section_summary: @updated_fields[:section_summary],
  )
end

Then(/^the manual is published as a major update$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_manual_is_drafted_to_publishing_api(@manual.id, extra_attributes: { update_type: "major" })
end

Then(/^the manual is published as a minor update$/) do
  # We don't use the update_type on the publish API, we fallback to what we set
  # when drafting the content
  check_manual_is_drafted_to_publishing_api(@manual.id, extra_attributes: { update_type: "minor" })
end

When(/^I add another section to the manual$/) do
  title = "Section 2"

  fields = {
    section_title: title,
    section_summary: "#{title} summary",
    section_body: "#{title} body",
  }

  create_manual_document(@manual_title, fields)

  @new_document = most_recently_created_manual.documents.to_a.last
end

Then(/^I see no visible change note in the manual document edit form$/) do
  document = @documents.first
  check_change_note_value(@manual_title, document.title, "")
end

When(/^I add invalid HTML to the document body$/) do
  fill_in :body, with: "<script>alert('naughty naughty');</script>"
end

When(/^I create another manual with the same slug$/) do
  create_manual(@manual_fields)
end

When(/^I create a section with duplicate title$/) do
  create_manual_document(@manual_fields.fetch(:title), @document_fields)
end

Then(/^the manual and its documents have failed to publish$/) do
  expect(page).to have_content("This manual was sent for publishing")
  expect(page).to have_content("something went wrong. Our team has been notified.")
end

Then(/^the manual and its documents are queued for publishing$/) do
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

When(/^I reorder the documents$/) do
  click_on("Reorder sections")
  elems = page.all(".reorderable-document-list li.ui-sortable-handle")
  elems[0].drag_to(elems[1])
  click_on("Save section order")
  @reordered_document_attributes = [
    @attributes_for_documents[1],
    @attributes_for_documents[0]
  ]
end

Then(/^the order of the documents in the manual should have been updated$/) do
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
