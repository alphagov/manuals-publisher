require "cma_case_service_registry"

module CmaCaseHelpers

  def create_cma_case(*args)
    create_document(:cma_case, *args)
  end

  def check_slug_updated_with_panopticon(old_slug, new_slug)
    expect(fake_panopticon).to have_received(:put_artefact!)
      .with(panopticon_id_for_slug(old_slug), hash_including(slug: new_slug))
  end

  def change_cma_case_without_saving(title, fields)
    go_to_edit_page_for_cma_case(title)
    fill_in_fields(fields)
  end

  def check_for_cma_case_body_preview
    expect(current_path).to match(%r{/cma-cases/([0-9a-f-]+|new)})
    within(".preview") do
      expect(page).to have_css("p", text: "Body for preview")
    end
  end

  def seed_cases(number_of_cases, state: "draft")
    services = CmaCaseServiceRegistry.new

    docs = number_of_cases.times.map do
      services.create(
        title: "Specialist Document #{SecureRandom.hex}",
        summary: "summary",
        body: "## Header" + ("\n\nPraesent commodo cursus magna, vel scelerisque nisl consectetur et." * 10),
        opened_date: "2014-01-01",
        market_sector: "agriculture-environment-and-natural-resources",
        case_state: "open",
        case_type: "ca98",
        outcome_type: "ca98-commitment",
        document_type: "cma_case",
      ).call
    end

    if state == "published"
      docs.each { |doc| services.publish(doc.id).call }
    end

    if state == "withdrawn"
      docs.each do |doc|
        services.publish(doc.id).call
        services.withdraw(doc.id).call
      end
    end

    docs
  end

  def go_to_cma_case_index
    visit_path_if_elsewhere(cma_cases_path)
  end

  def go_to_show_page_for_cma_case(*args)
    go_to_show_page_for_document(:cma_case, *args)
  end

  def check_cma_case_exists_with(*args)
    check_document_exists_with(:cma_case, *args)
  end

  def go_to_edit_page_for_cma_case(*args)
    go_to_edit_page_for_document(:cma_case, *args)
  end

  def update_title_and_republish_cma_case(current_title, args)
    updated_title = args.fetch(:to)

    go_to_edit_page_for_cma_case(current_title)

    fill_in_fields(
      title: updated_title,
    )

    save_document
    publish_document
  end

  def withdraw_cma_case(*args)
    withdraw_document(:cma_case, *args)
  end

  def edit_cma_case(*args)
    edit_document(:cma_case, *args)
  end

  def check_for_new_cma_case_title(*args)
    check_for_new_document_title(:cma_case, *args)
  end

end
