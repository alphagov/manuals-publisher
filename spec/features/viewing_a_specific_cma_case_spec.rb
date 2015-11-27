require 'spec_helper'

RSpec.feature "Creating a CMA case", type: :feature, js: true do

  def log_in_as_editor(editor)
    user = FactoryGirl.create(editor)
    GDS::SSO.test_user = user
  end

  def cma_case_content_item(n)
    {
      "content_id" => SecureRandom.uuid,
      "base_path" => "/cma-cases/example-cma-case-#{n}",
      "title" => "Example CMA Case #{n}",
      "description" => "This is the summary of example CMA case #{n}",
      "format" => "cma_case",
      "publishing_app" => "specialist-publisher",
      "rendering_app" => "specialist-frontend",
      "locale" => "en",
      "phase" => "live",
      "public_updated_at" => "2015-11-16T11:53:30.000+00:00",
      "details" => {
        "body" => "## Header" + ("\r\n\r\nThis is the long body of an example CMA case" * 10),
        "metadata" => {
          "opened_date" => "2014-01-01",
          "closed_date" => "",
          "case_type" => "ca98-and-civil-cartels",
          "case_state" => "open",
          "market_sector" => ["energy"],
          "outcome_type" => "",
          "document_type" => "cma_case",
        }
      },
      "routes" => [
        {
          "path" => "/cma-cases/example-cma-case",
          "type" => "exact",
        }
      ],
      "redirects" => [],
      "update_type" => "major",
      "links" => {
        "organisations" => ["957eb4ec-089b-4f71-ba2a-dc69ac8919ea"]
      }
    }
  end

  before do
    log_in_as_editor(:cma_editor)

    fields = [
      :base_path,
      :content_id,
      :title,
      :public_updated_at,
    ]

    cma_cases = []

    10.times do |n|
      cma_cases << cma_case_content_item(n)
    end

    publishing_api_has_fields_for_format('cma_case', cma_cases, fields)

    publishing_api_has_item(cma_cases[0])
  end

  scenario "Viewing a specific case" do
    visit "/cma-cases"

    expect(page.status_code).to eq(200)
    expect(page).to have_content("Example CMA Case 0")
    expect(page).to have_content("Example CMA Case 1")
    expect(page).to have_content("Example CMA Case 2")

    click_link "Example CMA Case 0"

    expect(page.status_code).to eq(200)
    expect(page).to have_content("Example CMA Case 0")
    expect(page).to have_content("This is the long body of an example CMA case")
    expect(page).to have_content("This is the summary of example CMA case 0")
    expect(page).to have_content("2014-01-01")
    expect(page).to have_content("CA98 and civil cartels")
    expect(page).to have_content("Energy")
  end

end
