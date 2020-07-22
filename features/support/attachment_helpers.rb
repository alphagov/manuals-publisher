module AttachmentHelpers
  def test_asset_manager_base_url
    Plek.current.find("asset-manager")
  end

  def add_attachment_to_section(section_title, attachment_title)
    if page.has_css?("a", text: section_title)
      click_on(section_title)
    elsif page.has_css?("a", text: "Edit")
      click_on("Edit")
    end

    unless current_path.include?("edit")
      click_link "Edit"
    end

    click_on "Add attachment"
    fill_in "Title", with: attachment_title
    attach_file "File", File.expand_path("../fixtures/greenpaper.pdf", File.dirname(__FILE__))

    stub_request(:post, "#{test_asset_manager_base_url}/assets")
      .to_return(
        body: JSON.dump(asset_manager_response),
        status: 201,
      )

    stub_request(:get, "#{test_asset_manager_base_url}/assets/#{asset_id}")
      .to_return(
        body: JSON.dump(asset_manager_response),
        status: 200,
      )

    click_on "Save attachment"
  end

  def asset_id
    "513a0efbed915d425e000002"
  end

  def asset_manager_response
    {
      "_response_info" => {
        "status" => "ok",
      },
      "content_type" => "image/jpeg",
      "file_url" => "https://stubbed-asset-manager.alphagov.co.uk/media/#{asset_id}/greenpaper.pdf",
      "id" => "https://stubbed-asset-manager.alphagov.co.uk/assets/#{asset_id}",
      "name" => "greenpaper.pdf",
      "state" => "clean",
    }
  end

  def check_for_an_attachment
    within(".attachments") do
      expect(page).to have_content("My attachment")
      expect(page).to have_content("[InlineAttachment:greenpaper.pdf]")
    end
  end

  def check_preview_contains_attachment_link(title)
    within(".preview") do
      expect(page).to have_css("a", text: title)
    end
  end

  def edit_attachment(_section_title, attachment_title, new_attachment_title, new_attachment_file_name)
    attachment_li = page.find(".attachments li", text: attachment_title)

    within(attachment_li) do
      click_link("edit")
    end

    fill_in "Title", with: new_attachment_title
    attach_file "File", fixture_filepath(new_attachment_file_name)

    stub_request(:put, "#{test_asset_manager_base_url}/assets/#{asset_id}")
      .to_return(
        body: JSON.dump(asset_manager_response),
        status: 200,
      )

    click_button "Save attachment"
  end

  def check_for_attachment_update(_section_title, _attachment_title, _attachment_file_name)
    expect(page).to have_css(".attachments li", text: @new_attachment_title)
    expect(page).to have_css(".attachments li", text: @new_attachment_file_name)
  end
end

RSpec.configuration.include AttachmentHelpers, type: :feature
World(AttachmentHelpers) if respond_to?(:World)
