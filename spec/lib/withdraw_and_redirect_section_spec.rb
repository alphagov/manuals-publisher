RSpec.describe WithdrawAndRedirectSection do
  let(:user) { User.gds_editor }
  let(:section) { FactoryBot.create(:section, state:) }
  let(:section_path) { section.slug }
  let(:state) { "published" }
  let(:redirect) { "/redirect/blah" }

  context "when only a draft section exists" do
    let(:state) { "draft" }

    it "raises an error if section is not published" do
      expect {
        WithdrawAndRedirectSection.new(user:, section_path:, redirect:, discard_draft: false).execute
      }.to raise_error(WithdrawAndRedirectSection::SectionNotPublishedError, "Unable to find a published Section Edition for this slug.")
      expect(SectionEdition.where(section_uuid: section.uuid).pluck(:state)).to eq(%w[draft])
    end
  end

  context "when multiple published sections" do
    let(:state) { "published" }

    it "raises an error if slug returns multiple published sections with differing section_uuids" do
      FactoryBot.create(:section_edition, state:, slug: section.slug, section_uuid: "new-one")
      expect {
        WithdrawAndRedirectSection.new(user:, section_path:, redirect:, discard_draft: false).execute
      }.to raise_error(
        WithdrawAndRedirectSection::SlugsWithMultiplePublishedSectionUUIDError,
        /The slug lookup returned multiple published editions with different Section UUIDs/,
      )
      expect(SectionEdition.where(section_uuid: section.uuid).pluck(:state)).to eq(%w[published])
    end

    it "allows multiple published sections and archive last one if they have the same section_uuids" do
      FactoryBot.create(:section_edition, state:, slug: section.slug, section_uuid: section.uuid)
      expect(Services.publishing_api).to receive(:unpublish)
      WithdrawAndRedirectSection.new(user:, section_path:, redirect:, discard_draft: false).execute
      expect(SectionEdition.where(section_uuid: section.uuid).pluck(:state)).to eq(%w[published archived])
    end
  end

  context "when section published with no draft" do
    it "unpublishes the section with discard_draft false to discard any leftover draft in publishing API" do
      expect(Services.publishing_api).to receive(:unpublish)
                                           .with(section.uuid,
                                                 type: "redirect",
                                                 alternative_path: redirect,
                                                 discard_drafts: false)
      WithdrawAndRedirectSection.new(user:, section_path:, redirect:, discard_draft: false).execute
      expect(SectionEdition.where(section_uuid: section.uuid).pluck(:state)).to eq(%w[archived])
    end

    it "unpublishes the section with discard_draft false even if sent a force discard draft flag cause this shouldn't be a draft" do
      expect(Services.publishing_api).to receive(:unpublish)
                                           .with(section.uuid,
                                                 type: "redirect",
                                                 alternative_path: redirect,
                                                 discard_drafts: false)
      WithdrawAndRedirectSection.new(user:, section_path:, redirect:, discard_draft: true).execute
      expect(SectionEdition.where(section_uuid: section.uuid).pluck(:state)).to eq(%w[archived])
    end
  end

  context "when section published with new draft" do
    before { FactoryBot.create(:section_edition, section_uuid: section.uuid, state: "draft", slug: section.slug) }

    it "sends discard_draft false and archives published edition and latest draft when not sent a discard_draft flag" do
      expect(Services.publishing_api).to receive(:unpublish)
                                           .with(section.uuid,
                                                 type: "redirect",
                                                 alternative_path: redirect,
                                                 discard_drafts: false)
      WithdrawAndRedirectSection.new(user:, section_path:, redirect:, discard_draft: false).execute
      expect(SectionEdition.where(section_uuid: section.uuid).pluck(:state)).to eq(%w[published archived])
    end

    it "sends discard_draft true and archives published edition and latest draft when sent a discard_draft flag" do
      expect(Services.publishing_api).to receive(:unpublish)
                                           .with(section.uuid,
                                                 type: "redirect",
                                                 alternative_path: redirect,
                                                 discard_drafts: true)
      WithdrawAndRedirectSection.new(user:, section_path:, redirect:, discard_draft: true).execute
      expect(SectionEdition.where(section_uuid: section.uuid).pluck(:state)).to eq(%w[published archived])
    end
  end

  context "when a dry run is flagged" do
    it "doesn't action the withdrawal" do
      expect(Services.publishing_api).to_not receive(:unpublish)
      WithdrawAndRedirectSection.new(user:, section_path:, redirect:, discard_draft: false, dry_run: true).execute
      expect(SectionEdition.where(section_uuid: section.uuid).pluck(:state)).to eq(%w[published])
    end
  end
end
