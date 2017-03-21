require "create_section_service"
require "update_section_service"
require "manuals_republisher"
require "manual_withdrawer"

module ManualHelpers
  def manual_repository
    RepositoryRegistry.create.manual_repository
  end

  def create_manual(fields, save: true)
    visit new_manual_path
    fill_in_fields(fields)

    yield if block_given?

    save_as_draft if save
  end

  def create_manual_without_ui(fields, organisation_slug: "ministry-of-tea")
    stub_organisation_details(organisation_slug)
    manual_repository_factory = RepositoryRegistry.create
      .organisation_scoped_manual_repository_factory
    repository = manual_repository_factory.call(organisation_slug)

    observers = ManualObserversRegistry.new
    service = CreateManualService.new(
      manual_repository: repository,
      manual_builder: ManualBuilder.create,
      listeners: observers.creation,
      attributes: fields.merge(organisation_slug: organisation_slug),
    )
    manual = service.call

    manual_repository.fetch(manual.id)
  end

  def create_section(manual_title, fields)
    go_to_manual_page(manual_title)
    click_on "Add section"

    fill_in_fields(fields)

    yield if block_given?

    save_as_draft
  end

  def create_section_without_ui(manual, fields, organisation_slug: "ministry-of-tea")
    manual_repository_factory = RepositoryRegistry.create.
      organisation_scoped_manual_repository_factory
    organisational_manual_repository = manual_repository_factory.call(organisation_slug)

    create_service_context = OpenStruct.new(
      params: {
        "manual_id" => manual.id,
        "section" => fields,
      }
    )

    service = CreateSectionService.new(
      manual_repository: organisational_manual_repository,
      context: create_service_context,
    )
    _, document = service.call

    document
  end

  def edit_manual(manual_title, new_fields)
    go_to_edit_page_for_manual(manual_title)
    fill_in_fields(new_fields)

    yield if block_given?

    save_as_draft
  end

  def edit_manual_without_ui(manual, fields, organisation_slug: "ministry-of-tea")
    stub_organisation_details(organisation_slug)
    manual_repository_factory = RepositoryRegistry.create
      .organisation_scoped_manual_repository_factory
    repository = manual_repository_factory.call(organisation_slug)

    observers = ManualObserversRegistry.new
    service = UpdateManualService.new(
      manual_repository: repository,
      manual_id: manual.id,
      attributes: fields.merge(organisation_slug: organisation_slug),
      listeners: observers.update,
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

  def edit_section_without_ui(manual, document, fields, organisation_slug: "ministry-of-tea")
    manual_repository_factory = RepositoryRegistry.create.
      organisation_scoped_manual_repository_factory
    organisational_manual_repository = manual_repository_factory.call(organisation_slug)

    service_context = OpenStruct.new(
      params: {
        "manual_id" => manual.id,
        "id" => document.id,
        "section" => fields,
      }
    )

    service = UpdateSectionService.new(
      manual_repository: organisational_manual_repository,
      context: service_context,
    )
    _, document = service.call

    document
  end

  def edit_manual_original_publication_date(manual_title)
    go_to_manual_page(manual_title)
    click_on("Edit first publication date")

    yield if block_given?

    save_as_draft
  end

  def withdraw_section(manual_title, section_title, change_note: nil, minor_update: true)
    go_to_manual_page(manual_title)
    click_on section_title

    click_on "Withdraw"

    fill_in "Change note", with: change_note unless change_note.blank?
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
    stub_rummager
    stub_publishing_api
    stub_organisation_details(organisation_slug)
  end

  def publish_manual_without_ui(manual, organisation_slug: "ministry-of-tea")
    stub_manual_publication_observers(organisation_slug)

    observers = ManualObserversRegistry.new
    service = PublishManualService.new(
      manual_repository: RepositoryRegistry.create.manual_repository,
      listeners: observers.publication,
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

    attributes.values.each do |attr_val|
      expect(page).to have_content(attr_val)
    end
  end

  def check_section_exists(manual_id, section_id)
    manual = manual_repository.fetch(manual_id)

    manual.documents.any? { |document| document.id == section_id }
  end

  def check_section_was_removed(manual_id, section_id)
    manual = manual_repository.fetch(manual_id)

    manual.removed_documents.any? { |document| document.id == section_id }
  end

  def go_to_edit_page_for_manual(manual_title)
    go_to_manual_page(manual_title)
    click_on("Edit manual")
  end

  def check_for_errors_for_fields(field)
    expect(page).to have_content("#{field.titlecase} can't be blank")
  end

  def check_content_preview_link(slug)
    preview_url = "#{Plek.current.find('draft-origin')}/#{slug}"
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

  def check_manual_and_documents_were_published(manual, document, manual_attrs, document_attrs)
    check_manual_is_published_to_publishing_api(manual.id)
    check_section_is_published_to_publishing_api(document.id)

    check_manual_is_published_to_rummager(manual.slug, manual_attrs)
    check_section_is_published_to_rummager(document.slug, document_attrs, manual_attrs)
  end

  def check_manual_was_published(manual)
    check_manual_is_published_to_publishing_api(manual.id)
  end

  def check_manual_was_not_published(manual)
    check_manual_is_not_published_to_publishing_api(manual.id)
  end

  def check_section_was_published(document)
    check_section_is_published_to_publishing_api(document.id)
  end

  def check_section_was_not_published(document)
    check_section_is_not_published_to_publishing_api(document.id)
  end

  def check_section_was_withdrawn_with_redirect(document, redirect_path)
    check_section_is_unpublished_from_publishing_api(document.id, type: "redirect", alternative_path: redirect_path, discard_drafts: true)
    check_section_is_withdrawn_from_rummager(document)
  end

  def section_repository(manual)
    RepositoryRegistry.create.section_repository_factory.call(manual)
  end

  def check_section_is_archived_in_db(manual, document_id)
    expect(section_repository(manual).fetch(document_id)).to be_withdrawn
  end

  def check_manual_is_published_to_rummager(slug, attrs)
    expect(fake_rummager).to have_received(:add_document)
      .with(
        ManualIndexableFormatter::RUMMAGER_DOCUMENT_TYPE,
        "/#{slug}",
        hash_including(
          title: attrs.fetch(:title),
          link: "/#{slug}",
          indexable_content: attrs.fetch(:summary),
        )
      ).at_least(:once)
  end

  def check_manual_is_not_published_to_rummager(slug)
    expect(fake_rummager).not_to have_received(:add_document)
      .with(
        ManualIndexableFormatter::RUMMAGER_DOCUMENT_TYPE,
        "/#{slug}",
        anything
      )
  end

  def check_manual_is_not_published_to_rummager_with_attrs(slug, attrs)
    expect(fake_rummager).not_to have_received(:add_document)
      .with(
        ManualIndexableFormatter::RUMMAGER_DOCUMENT_TYPE,
        "/#{slug}",
        hash_including(
          title: attrs.fetch(:title),
          link: "/#{slug}",
          indexable_content: attrs.fetch(:summary),
        )
      )
  end

  def check_manual_is_drafted_to_publishing_api(content_id, extra_attributes: {}, number_of_drafts: 1, with_matcher: nil)
    raise ArgumentError, "can't specify both extra_attributes and with_matcher" if with_matcher.present? && !extra_attributes.empty?

    if with_matcher.nil?
      attributes = {
        "schema_name" => ManualPublishingAPIExporter::PUBLISHING_API_SCHEMA_NAME,
        "document_type" => ManualPublishingAPIExporter::PUBLISHING_API_DOCUMENT_TYPE,
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
        "schema_name" => SectionPublishingAPIExporter::PUBLISHING_API_SCHEMA_NAME,
        "document_type" => SectionPublishingAPIExporter::PUBLISHING_API_DOCUMENT_TYPE,
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

  def check_section_is_published_to_rummager(slug, attrs, manual_attrs)
    expect(fake_rummager).to have_received(:add_document)
      .with(
        SectionIndexableFormatter::RUMMAGER_DOCUMENT_TYPE,
        "/#{slug}",
        hash_including(
          title: "#{manual_attrs.fetch(:title)}: #{attrs.fetch(:section_title)}",
          link: "/#{slug}",
          indexable_content: attrs.fetch(:section_body),
        )
      ).at_least(:once)
  end

  def check_section_is_not_published_to_rummager(slug)
    expect(fake_rummager).not_to have_received(:add_document)
      .with(
        SectionIndexableFormatter::RUMMAGER_DOCUMENT_TYPE,
        "/#{slug}",
        anything
      )
  end

  def check_section_is_not_published_to_rummager_with_attrs(slug, attrs, manual_attrs)
    expect(fake_rummager).not_to have_received(:add_document)
      .with(
        SectionIndexableFormatter::RUMMAGER_DOCUMENT_TYPE,
        "/#{slug}",
        hash_including(
          title: "#{manual_attrs.fetch(:title)}: #{attrs.fetch(:section_title)}",
          link: "/#{slug}",
          indexable_content: attrs.fetch(:section_body),
        )
      )
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

  def check_change_note_value(manual_title, document_title, expected_value)
    go_to_manual_page(manual_title)
    click_on document_title
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
    document_fields = {
      section_title: "Section 1",
      section_summary: "Section 1 summary",
      section_body: "Section 1 body",
    }
    create_section(@manual_fields.fetch(:title), document_fields)

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

  def check_manual_is_withdrawn(manual, documents)
    assert_publishing_api_unpublish(manual.id, type: "gone")
    documents.each { |d| assert_publishing_api_unpublish(d.id, type: "gone") }
    check_manual_is_withdrawn_from_rummager(manual, documents)
  end

  def check_manual_is_withdrawn_from_rummager(manual, documents)
    expect(fake_rummager).to have_received(:delete_document)
      .with(
        ManualIndexableFormatter::RUMMAGER_DOCUMENT_TYPE,
        "/#{manual.slug}",
      )

    documents.each do |document|
      expect(fake_rummager).to have_received(:delete_document)
        .with(
          SectionIndexableFormatter::RUMMAGER_DOCUMENT_TYPE,
          "/#{document.slug}",
        )
    end
  end

  def check_section_is_withdrawn_from_rummager(document)
    expect(fake_rummager).to have_received(:delete_document)
      .with(
        SectionIndexableFormatter::RUMMAGER_DOCUMENT_TYPE,
        "/#{document.slug}",
      )
  end

  def check_manual_has_organisation_slug(attributes, organisation_slug)
    go_to_manual_page(attributes.fetch(:title))

    expect(page.body).to have_content(organisation_slug)
  end

  def create_documents_for_manual(count:, manual_fields:)
    attributes_for_documents = (1..count).map do |n|
      title = "Section #{n}"

      {
        title: title,
        slug: "guidance/example-manual-title/section-#{n}",
        fields: {
          section_title: title,
          section_summary: "Section #{n} summary",
          section_body: "Section #{n} body",
        }
      }
    end

    attributes_for_documents.each do |attributes|
      create_section(manual_fields.fetch(:title), attributes[:fields])
    end

    attributes_for_documents
  end

  def create_documents_for_manual_without_ui(manual:, count:)
    (1..count).map do |n|
      attributes = {
        title: "Section #{n}",
        summary: "Section #{n} summary",
        body: "Section #{n} body"
      }

      create_section_without_ui(manual, attributes)
    end
  end

  def most_recently_created_manual
    RepositoryRegistry.create.manual_repository.all.first
  end

  def document_fields(document)
    {
      section_title: document.title,
      section_summary: document.summary,
      section_body: document.body,
    }
  end

  def check_document_withdraw_link_not_visible(manual, document)
    # Don't give them the option...
    go_to_manual_page(manual.title)
    click_on document.title
    expect(page).not_to have_button("Withdraw")

    # ...and if they get here anyway, throw them out
    visit withdraw_manual_section_path(manual, document)
    expect(current_path).to eq manual_section_path(manual.id, document.id)
    expect(page).to have_text("You don't have permission to withdraw manual sections.")
  end

  def change_notes_sent_to_publishing_api_include_document(document)
    ->(request) do
      data = JSON.parse(request.body)
      change_notes = data["details"]["change_notes"]
      change_notes.detect { |change_note|
        (change_note["base_path"] == "/#{document.slug}") &&
          (change_note["title"] == document.title) &&
          (change_note["change_note"] == document.change_note)
      }.present?
    end
  end

  def check_manual_is_drafted_and_published_with_first_published_date_only(manual, expected_date, how_many_times: 1)
    # We don't use the update_type on the publish API, we fallback to what we set
    # when drafting the content
    check_section_is_drafted_to_publishing_api(
      manual.id,
      with_matcher: ->(request) do
        data = JSON.parse(request.body)
        (data["first_published_at"] == expected_date.iso8601) &&
        !data.key?("public_updated_at")
      end,
      number_of_drafts: how_many_times
    )
    check_manual_was_published(manual)
  end

  def check_section_is_drafted_and_published_with_first_published_date_only(document, expected_date, how_many_times: 1)
    # We don't use the update_type on the publish API, we fallback to what we set
    # when drafting the content
    check_section_is_drafted_to_publishing_api(
      document.id,
      with_matcher: ->(request) do
        data = JSON.parse(request.body)
        (data["first_published_at"] == expected_date.iso8601) &&
        !data.key?("public_updated_at")
      end,
      number_of_drafts: how_many_times
    )

    check_section_was_published(document)
  end

  def check_manual_is_drafted_and_published_with_all_public_timestamps(manual, expected_date, how_many_times: 1)
    # We don't use the update_type on the publish API, we fallback to what we set
    # when drafting the content
    check_section_is_drafted_to_publishing_api(
      manual.id,
      with_matcher: ->(request) do
        data = JSON.parse(request.body)
        (data["first_published_at"] == expected_date.iso8601) &&
        (data["public_updated_at"] == expected_date.iso8601)
      end,
      number_of_drafts: how_many_times
    )
    check_manual_was_published(manual)
  end

  def check_section_is_drafted_and_published_with_all_public_timestamps(document, expected_date, how_many_times: 1)
    # We don't use the update_type on the publish API, we fallback to what we set
    # when drafting the content
    check_section_is_drafted_to_publishing_api(
      document.id,
      with_matcher: ->(request) do
        data = JSON.parse(request.body)
        (data["first_published_at"] == expected_date.iso8601) &&
        (data["public_updated_at"] == expected_date.iso8601)
      end,
      number_of_drafts: how_many_times
    )

    check_section_was_published(document)
  end

  def check_manual_is_drafted_and_published_with_no_public_timestamps(manual, how_many_times: 1)
    # We don't use the update_type on the publish API, we fallback to what we set
    # when drafting the content
    check_section_is_drafted_to_publishing_api(
      manual.id,
      with_matcher: ->(request) do
        data = JSON.parse(request.body)
        !data.key?("first_published_at") &&
        !data.key?("public_updated_at")
      end,
      number_of_drafts: how_many_times
    )
    check_manual_was_published(manual)
  end

  def republish_manuals_without_ui
    logger = Logger.new(nil)
    republisher = ManualsRepublisher.new(logger)
    republisher.execute
  end
end
RSpec.configuration.include ManualHelpers, type: :feature
