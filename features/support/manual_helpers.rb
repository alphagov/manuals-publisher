require "manuals_republisher"
require "manual_withdrawer"
require "gds_api_constants"

module ManualHelpers
  def entity_id_for(entity)
    entity.is_a?(Section) ? entity.uuid : entity.id
  end

  def create_manual(fields, save: true)
    visit new_manual_path
    fill_in_fields(fields)

    yield if block_given?

    save_as_draft if save
  end

  def create_manual_without_ui(fields, organisation_slug: "ministry-of-tea")
    stub_organisation_details(organisation_slug)

    user = FactoryBot.build(:generic_editor, organisation_slug: organisation_slug)

    service = Manual::CreateService.new(
      user: user,
      attributes: fields.merge(organisation_slug: organisation_slug),
    )
    manual = service.call

    Manual.find(manual.id, FactoryBot.build(:gds_editor))
  end

  def create_section(manual_title, fields)
    go_to_manual_page(manual_title)
    click_on "Add section"

    fill_in_fields(fields)

    yield if block_given?

    save_as_draft
  end

  def create_expanded_section(manual_title, fields)
    go_to_manual_page(manual_title)
    click_on "Add section"

    fill_in_fields(fields)

    check "Remove collapsible content functionality (accordions)"

    yield if block_given?

    save_as_draft
  end

  def create_section_without_ui(manual, fields, organisation_slug: "ministry-of-tea")
    user = FactoryBot.build(:generic_editor, organisation_slug: organisation_slug)

    service = Section::CreateService.new(
      user: user,
      manual_id: manual.id,
      attributes: fields,
    )
    _, section = service.call

    section
  end

  def edit_manual(manual_title, new_fields)
    go_to_edit_page_for_manual(manual_title)
    fill_in_fields(new_fields)

    yield if block_given?

    save_as_draft
  end

  def edit_manual_without_ui(manual, fields, organisation_slug: "ministry-of-tea")
    stub_organisation_details(organisation_slug)

    user = FactoryBot.build(:generic_editor, organisation_slug: organisation_slug)

    service = Manual::UpdateService.new(
      user: user,
      manual_id: manual.id,
      attributes: fields.merge(organisation_slug: organisation_slug),
    )
    manual = service.call

    manual
  end

  def edit_section(manual_title, section_title, new_fields)
    go_to_manual_page(manual_title)
    click_on section_title
    click_on "Edit"
    fill_in_fields(new_fields)

    yield if block_given?

    save_as_draft
  end

  def edit_section_without_ui(manual, section, fields, organisation_slug: "ministry-of-tea")
    user = FactoryBot.build(:generic_editor, organisation_slug: organisation_slug)

    service = Section::UpdateService.new(
      user: user,
      manual_id: manual.id,
      section_uuid: section.uuid,
      attributes: fields,
    )
    _, section = service.call

    section
  end

  def edit_manual_original_publication_date(manual_title)
    go_to_manual_page(manual_title)
    click_on("Edit first publication date")

    yield if block_given?

    save_as_draft
  end

  def discard_draft_manual(manual_title)
    go_to_manual_page(manual_title)

    click_on "Discard draft"
  end

  def withdraw_section(manual_title, section_title, change_note: nil, minor_update: true)
    go_to_manual_page(manual_title)
    click_on section_title

    click_on "Withdraw"

    fill_in "Change note", with: change_note if change_note.present?
    if minor_update
      choose "Minor update"
    end

    click_on "Yes"
  end

  def save_as_draft
    click_on "Save as draft"
  end

  def publish_manual
    click_on "Publish manual"
  end

  def stub_manual_publication_observers(organisation_slug)
    stub_publishing_api
    stub_organisation_details(organisation_slug)
  end

  def publish_manual_without_ui(manual, organisation_slug: "ministry-of-tea")
    stub_manual_publication_observers(organisation_slug)

    service = Manual::PublishService.new(
      user: FactoryBot.build(:gds_editor),
      manual_id: manual.id,
      version_number: manual.version_number,
    )
    service.call
  end

  def check_manual_exists_with(attributes)
    go_to_manual_page(attributes.fetch(:title))
    expect(page).to have_content(attributes.fetch(:summary))
  end

  def check_manual_does_not_exist_with(attributes)
    visit manuals_path
    expect(page).not_to have_content(attributes.fetch(:title))
  end

  def check_section_exists_with(manual_title, attributes)
    go_to_manual_page(manual_title)
    click_on(attributes.fetch(:section_title))

    attributes.each_value do |attr_val|
      expect(page).to have_content(attr_val)
    end
  end

  def check_section_exists(manual_id, section_uuid)
    manual = Manual.find(manual_id, FactoryBot.build(:gds_editor))

    manual.sections.any? { |section| section.uuid == section_uuid }
  end

  def check_section_was_removed(manual_id, section_uuid)
    manual = Manual.find(manual_id, FactoryBot.build(:gds_editor))

    manual.removed_sections.any? { |section| section.uuid == section_uuid }
  end

  def go_to_edit_page_for_manual(manual_title)
    go_to_manual_page(manual_title)
    click_on("Edit manual")
  end

  def check_for_errors_for_fields(field)
    expect(page).to have_content("#{field.titlecase} can't be blank")
  end

  def check_content_preview_link(slug)
    preview_url = "#{Plek.new.external_url_for('draft-origin')}/#{slug}"
    expect(page).to have_link("Preview draft", href: preview_url)
  end

  def check_live_link(slug)
    live_url = "#{Plek.current.website_root}/#{slug}"
    expect(page).to have_link("View on website", href: live_url)
  end

  def go_to_manual_page(manual_title)
    visit manuals_path
    click_link manual_title
  end

  def check_manual_and_sections_were_published(manual, section, _manual_attrs, _section_attrs)
    check_manual_is_published_to_publishing_api(manual.id)
    check_section_is_published_to_publishing_api(section.uuid)
  end

  def check_manual_was_published(manual)
    entity_id = entity_id_for(manual)
    check_manual_is_published_to_publishing_api(entity_id)
  end

  def check_manual_was_not_published(manual)
    check_manual_is_not_published_to_publishing_api(manual.id)
  end

  def check_section_was_published(section)
    check_section_is_published_to_publishing_api(section.uuid)
  end

  def check_section_was_not_published(section)
    check_section_is_not_published_to_publishing_api(section.uuid)
  end

  def check_section_was_withdrawn_with_redirect(section, redirect_path)
    check_section_is_unpublished_from_publishing_api(section.uuid, type: "redirect", alternative_path: redirect_path, discard_drafts: true)
  end

  def check_section_is_archived_in_db(manual, section_uuid)
    expect(Section.find(manual, section_uuid)).to be_withdrawn
  end

  def check_manual_is_drafted_to_publishing_api(content_id, extra_attributes: {}, number_of_drafts: 1, with_matcher: nil)
    raise ArgumentError, "can't specify both extra_attributes and with_matcher" if with_matcher.present? && !extra_attributes.empty?

    if with_matcher.nil?
      attributes = {
        "schema_name" => GdsApiConstants::PublishingApi::MANUAL_SCHEMA_NAME,
        "document_type" => GdsApiConstants::PublishingApi::MANUAL_DOCUMENT_TYPE,
        "rendering_app" => "manuals-frontend",
        "publishing_app" => "manuals-publisher",
      }.merge(extra_attributes)
      with_matcher = request_json_including(attributes)
    end
    assert_publishing_api_put_content(content_id, with_matcher, number_of_drafts)
  end

  def check_manual_is_published_to_publishing_api(content_id, times: 1)
    assert_publishing_api_publish(content_id, nil, times)
  end

  def check_manual_is_not_published_to_publishing_api(content_id)
    assert_publishing_api_publish(content_id, nil, 0)
  end

  def check_draft_has_been_discarded_in_publishing_api(content_id)
    assert_publishing_api_discard_draft(content_id)
  end

  def check_section_is_drafted_to_publishing_api(content_id, extra_attributes: {}, number_of_drafts: 1, with_matcher: nil)
    raise ArgumentError, "can't specify both extra_attributes and with_matcher" if with_matcher.present? && !extra_attributes.empty?

    if with_matcher.nil?
      attributes = {
        "schema_name" => GdsApiConstants::PublishingApi::SECTION_SCHEMA_NAME,
        "document_type" => GdsApiConstants::PublishingApi::SECTION_DOCUMENT_TYPE,
        "rendering_app" => "manuals-frontend",
        "publishing_app" => "manuals-publisher",
      }.merge(extra_attributes)
      with_matcher = request_json_including(attributes)
    end
    assert_publishing_api_put_content(content_id, with_matcher, number_of_drafts)
  end

  def check_section_is_published_to_publishing_api(content_id, times: 1)
    assert_publishing_api_publish(content_id, nil, times)
  end

  def check_section_is_not_published_to_publishing_api(content_id)
    assert_publishing_api_publish(content_id, nil, 0)
  end

  def check_section_is_unpublished_from_publishing_api(content_id, unpublishing_attributes)
    assert_publishing_api_unpublish(content_id, unpublishing_attributes)
  end

  def check_for_document_body_preview(text)
    within(".preview") do
      expect(page).to have_css("p", text: text)
    end
  end

  def copy_embed_code_for_attachment_and_paste_into_section_body(title)
    snippet = within(".attachments") do
      page
        .find("li", text: /#{title}/)
        .find("span.snippet")
        .text
    end

    body_text = find("#section_body").value
    fill_in("Section body", with: body_text + snippet)
  end

  def check_change_note_value(manual_title, section_title, expected_value)
    go_to_manual_page(manual_title)
    click_on section_title
    click_on "Edit section"

    change_note_field_value = page.find("textarea[name='section[change_note]']").text
    expect(change_note_field_value).to eq(expected_value)
  end

  def check_that_change_note_fields_are_present(note_field_only: false, minor_update: false, note: "")
    unless note_field_only
      expect(page).to have_field("Minor update", checked: minor_update)
      expect(page).to have_field("Major update", checked: !minor_update)
      # the note field is only visible for major updates, so we have to reveal it
      # if we think it will be a minor update alread
      choose("Major update") if minor_update
    end
    expect(page).to have_field("Change note", with: note)
  end

  def check_manual_can_be_created
    @manual_fields = {
      title: "Example Manual Title",
      summary: "Nullam quis risus eget urna mollis ornare vel eu leo.",
    }

    create_manual(@manual_fields)
    check_manual_exists_with(@manual_fields)
  end

  def check_manual_cannot_be_published
    section_fields = {
      section_title: "Section 1",
      section_summary: "Section 1 summary",
      section_body: "Section 1 body",
    }
    create_section(@manual_fields.fetch(:title), section_fields)

    go_to_manual_page(@manual_fields.fetch(:title))
    expect(page).not_to have_button("Publish")
  end

  def change_manual_without_saving(title, fields)
    go_to_edit_page_for_manual(title)
    fill_in_fields(fields)
  end

  def check_for_manual_body_preview
    expect(current_path).to match(%r{/manuals/([0-9a-f-]+|new)})
    within(".preview") do
      expect(page).to have_css("p", text: "Body for preview")
    end
  end

  def check_for_clashing_section_slugs
    expect(page).to have_content("Warning: There are duplicate section slugs in this manual")
  end

  def withdraw_manual_without_ui(manual)
    logger = Logger.new(nil)
    withdrawer = ManualWithdrawer.new(logger)
    withdrawer.execute(manual.id)
  end

  def check_manual_is_withdrawn(manual, sections)
    assert_publishing_api_unpublish(manual.id, type: "gone")
    sections.each { |s| assert_publishing_api_unpublish(s.uuid, type: "gone") }
  end

  def check_manual_has_organisation_slug(attributes, organisation_slug)
    go_to_manual_page(attributes.fetch(:title))

    expect(page.body).to have_content(organisation_slug)
  end

  def create_sections_for_manual(count:, manual_fields:)
    attributes_for_sections = (1..count).map do |n|
      title = "Section #{n}"

      {
        title: title,
        slug: "guidance/example-manual-title/section-#{n}",
        fields: {
          section_title: title,
          section_summary: "Section #{n} summary",
          section_body: "Section #{n} body",
        },
      }
    end

    attributes_for_sections.each do |attributes|
      create_section(manual_fields.fetch(:title), attributes[:fields])
    end

    attributes_for_sections
  end

  def create_sections_for_manual_without_ui(manual:, count:)
    (1..count).map do |n|
      attributes = {
        title: "Section #{n}",
        summary: "Section #{n} summary",
        body: "Section #{n} body",
      }

      create_section_without_ui(manual, attributes)
    end
  end

  def most_recently_created_manual
    Manual.all(FactoryBot.build(:gds_editor)).first
  end

  def section_fields(section)
    {
      section_title: section.title,
      section_summary: section.summary,
      section_body: section.body,
    }
  end

  def check_section_withdraw_link_not_visible(manual, section)
    # Don't give them the option...
    go_to_manual_page(manual.title)
    click_on section.title
    expect(page).not_to have_button("Withdraw")

    # ...and if they get here anyway, throw them out
    visit withdraw_manual_section_path(manual, section)
    expect(current_path).to eq manual_section_path(manual.id, section.uuid)
    expect(page).to have_text("You don't have permission to withdraw manual sections.")
  end

  def change_notes_sent_to_publishing_api_include_section(section)
    lambda do |request|
      data = JSON.parse(request.body)
      change_notes = data["details"]["change_notes"]
      change_notes.detect { |change_note|
        (change_note["base_path"] == "/#{section.slug}") &&
          (change_note["title"] == section.title) &&
          (change_note["change_note"] == section.change_note)
      }.present?
    end
  end

  def check_manual_is_drafted_and_published_with_first_published_date_only(manual, expected_date, how_many_times: 1)
    # We don't use the update_type on the publish API, we fallback to what we set
    # when drafting the content
    check_section_is_drafted_to_publishing_api(
      manual.id,
      with_matcher: lambda do |request|
        data = JSON.parse(request.body)
        (data["first_published_at"] == expected_date.as_json) &&
        !data.key?("public_updated_at")
      end,
      number_of_drafts: how_many_times,
    )
    check_manual_was_published(manual)
  end

  def check_section_is_drafted_and_published_with_first_published_date_only(section, expected_date, how_many_times: 1)
    # We don't use the update_type on the publish API, we fallback to what we set
    # when drafting the content
    check_section_is_drafted_to_publishing_api(
      section.uuid,
      with_matcher: lambda do |request|
        data = JSON.parse(request.body)
        (data["first_published_at"] == expected_date.as_json) &&
        !data.key?("public_updated_at")
      end,
      number_of_drafts: how_many_times,
    )

    check_section_was_published(section)
  end

  def check_manual_is_drafted_and_published_with_all_public_timestamps(manual, expected_date, how_many_times: 1)
    # We don't use the update_type on the publish API, we fallback to what we set
    # when drafting the content
    check_section_is_drafted_to_publishing_api(
      manual.id,
      with_matcher: lambda do |request|
        data = JSON.parse(request.body)
        (data["first_published_at"] == expected_date.as_json) &&
        (data["public_updated_at"] == expected_date.as_json)
      end,
      number_of_drafts: how_many_times,
    )
    check_manual_was_published(manual)
  end

  def check_section_is_drafted_and_published_with_all_public_timestamps(section, expected_date, how_many_times: 1)
    # We don't use the update_type on the publish API, we fallback to what we set
    # when drafting the content
    check_section_is_drafted_to_publishing_api(
      section.uuid,
      with_matcher: lambda do |request|
        data = JSON.parse(request.body)
        (data["first_published_at"] == expected_date.as_json) &&
        (data["public_updated_at"] == expected_date.as_json)
      end,
      number_of_drafts: how_many_times,
    )

    check_section_was_published(section)
  end

  def check_manual_is_drafted_and_published_with_no_public_timestamps(manual, how_many_times: 1)
    # We don't use the update_type on the publish API, we fallback to what we set
    # when drafting the content
    check_section_is_drafted_to_publishing_api(
      entity_id_for(manual),
      with_matcher: lambda do |request|
        data = JSON.parse(request.body)
        !data.key?("first_published_at") &&
        !data.key?("public_updated_at")
      end,
      number_of_drafts: how_many_times,
    )
    check_manual_was_published(manual)
  end

  def republish_manuals_without_ui
    logger = Logger.new(nil)
    republisher = ManualsRepublisher.new(logger)
    user = FactoryBot.build(:gds_editor)
    manuals = Manual.all(user)
    republisher.execute(manuals)
  end

  def check_for_slug_clash_warning
    expect(page).to have_content("You can't publish it until you change the title.")
  end

  def check_for_javascript_usage_error(field)
    expect(page).to have_content("#{field} cannot include invalid Govspeak, invalid HTML, any JavaScript or images hosted on sites except for")
  end

  def stub_http_server_error
    allow_any_instance_of(Manual::PublishService).to receive(:call).and_raise(GdsApi::HTTPServerError.new(500))
  end

  def stub_http_error_response
    allow_any_instance_of(Manual::PublishService).to receive(:call).and_raise(GdsApi::HTTPErrorResponse.new(400))
  end
end

RSpec.configuration.include ManualHelpers, type: :feature
World(ManualHelpers) if respond_to?(:World)
