describe Publishing::UnpublishAdapter do
  let(:manual_id) { "a55242ed-178f-4716-8bb3-5d4f82d38531" }
  let(:manual) { FactoryBot.create(:manual, id: manual_id, state: "published") }
  let(:section_one_uuid) { "11111111-b637-40b7-ada4-f19ce460e5e9" }
  let(:section_one) { FactoryBot.create(:section, uuid: section_one_uuid, state: "published") }
  let(:section_two_uuid) { "22222222-b637-40b7-ada4-f19ce460e5e9" }
  let(:section_two) { FactoryBot.create(:section, uuid: section_two_uuid, state: "published") }

  before do
    manual.sections = [section_one, section_two]
  end

  describe "#unpublish_and_redirect_manual_and_sections" do
    let(:redirect) { "/blah/redirect" }
    let(:redirects) do
      [
        { path: "/#{manual.slug}", type: "exact", destination: redirect },
        { path: "/#{manual.slug}/updates", type: "exact", destination: redirect },
      ]
    end

    it "unpublishes and redirects manual plus sections via Publishing API with discard draft false" do
      expect(Services.publishing_api).to receive(:unpublish).with(
        manual_id, type: "redirect", redirects:, discard_drafts: false
      )

      expect(Services.publishing_api).to receive(:unpublish).with(
        section_one_uuid, type: "redirect", discard_drafts: false, alternative_path: redirect
      )
      expect(Services.publishing_api).to receive(:unpublish).with(
        section_two_uuid, type: "redirect", discard_drafts: false, alternative_path: redirect
      )

      Publishing::UnpublishAdapter.unpublish_and_redirect_manual_and_sections(manual, redirect:, discard_drafts: false)
    end

    it "unpublishes and redirects manual plus sections via Publishing API with discard_draft true" do
      expect(Services.publishing_api).to receive(:unpublish).with(
        manual_id, type: "redirect", redirects:, discard_drafts: true
      )

      expect(Services.publishing_api).to receive(:unpublish).with(
        section_one_uuid, type: "redirect", discard_drafts: true, alternative_path: redirect
      )
      expect(Services.publishing_api).to receive(:unpublish).with(
        section_two_uuid, type: "redirect", discard_drafts: true, alternative_path: redirect
      )

      Publishing::UnpublishAdapter.unpublish_and_redirect_manual_and_sections(manual, redirect:, discard_drafts: true)
    end

    it "does not update the state of the manual" do
      allow(Services.publishing_api).to receive(:unpublish)
      Publishing::UnpublishAdapter.unpublish_and_redirect_manual_and_sections(manual, redirect:, discard_drafts: true)
      expect(manual.state).to eq "published"
    end
  end

  describe "#unpublish_and_redirect_section" do
    let(:redirect) { "/blah/redirect" }

    it "unpublishes and redirects a section via Publishing API with default discard_draft true" do
      expect(Services.publishing_api).to receive(:unpublish).with(
        section_one_uuid, type: "redirect", discard_drafts: true, alternative_path: redirect
      )
      Publishing::UnpublishAdapter.unpublish_and_redirect_section(section_one, redirect:)
    end

    it "unpublishes and redirects a section via Publishing API with discard draft false" do
      expect(Services.publishing_api).to receive(:unpublish).with(
        section_one_uuid, type: "redirect", discard_drafts: false, alternative_path: redirect
      )
      Publishing::UnpublishAdapter.unpublish_and_redirect_section(section_one, redirect:, discard_drafts: false)
    end

    it "marks a section as archived" do
      allow(Services.publishing_api).to receive(:unpublish)
      Publishing::UnpublishAdapter.unpublish_and_redirect_section(section_one, redirect:)
      expect(section_one.state).to eq "archived"
    end

    it "does not unpublish and redirect section if section is already archived" do
      section = FactoryBot.build(:section, uuid: section_one_uuid, state: "archived")
      expect(Services.publishing_api).to_not receive(:unpublish)
      Publishing::UnpublishAdapter.unpublish_and_redirect_section(section, redirect:)
      expect(section.state).to eq "archived"
    end
  end
end
