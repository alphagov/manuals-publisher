describe Publishing::PublishAdapter do
  let(:manual_id) { "a55242ed-178f-4716-8bb3-5d4f82d38531" }
  let(:manual) { FactoryBot.create(:manual, id: manual_id) }
  let(:section_uuid) { "11111111-b637-40b7-ada4-f19ce460e5e9" }
  let(:section) { FactoryBot.create(:section, uuid: section_uuid, state: "published") }
  let(:removed_section_uuid) { "22222222-b637-40b7-ada4-f19ce460e5e9" }
  let(:removed_section) { FactoryBot.create(:section, uuid: removed_section_uuid, state: "published") }

  before do
    manual.sections = [section]
    manual.removed_sections = [removed_section]

    allow(Services.publishing_api).to receive(:publish).with(anything, anything)
    allow(Services.publishing_api).to receive(:unpublish).with(anything, anything)
  end

  describe "#publish" do
    it "publishes manual and its sections to Publishing API" do
      expect(Services.publishing_api).to receive(:publish).with(manual_id, nil)
      Publishing::PublishAdapter.publish_manual_and_sections(manual)
    end

    it "publishes all manual's sections to Publishing API" do
      expect(Services.publishing_api).to receive(:publish).with(section_uuid, nil)
      Publishing::PublishAdapter.publish_manual_and_sections(manual)
    end

    it "marks all manual's sections as exported" do
      expect(section).to receive(:mark_as_exported!)
      Publishing::PublishAdapter.publish_manual_and_sections(manual)
    end

    it "unpublishes all manual's removed sections via Publishing API" do
      expect(Services.publishing_api).to receive(:unpublish).with(
        removed_section_uuid,
        type: "redirect",
        alternative_path: "/manual-slug",
        discard_drafts: true,
      )
      Publishing::PublishAdapter.publish_manual_and_sections(manual)
    end

    it "withdraws & marks all manual's removed sections as exported" do
      freeze_time do
        Publishing::PublishAdapter.publish_manual_and_sections(manual)
        expect(removed_section.reload.exported_at).to eq Time.zone.now
        expect(removed_section.reload.state).to eq("archived")
      end
    end

    context "when removed section is withdrawn" do
      let(:removed_section) { FactoryBot.create(:section, uuid: removed_section_uuid, state: "archived") }

      it "does not unpublish all manual's removed sections via Publishing API" do
        expect(Services.publishing_api).not_to receive(:unpublish).with(
          removed_section_uuid,
          anything,
        )

        Publishing::PublishAdapter.publish_manual_and_sections(manual)
      end
    end

    context "when action is republish" do
      it "publishes manual to Publishing API with update type set to republish" do
        expect(Services.publishing_api).to receive(:publish).with(manual_id, "republish")

        Publishing::PublishAdapter.publish_manual_and_sections(manual, republish: true)
      end

      it "publishes all manual's sections to Publishing API with update type set to republish" do
        expect(Services.publishing_api).to receive(:publish).with(section_uuid, "republish")

        Publishing::PublishAdapter.publish_manual_and_sections(manual, republish: true)
      end

      it "does not mark all manual's sections as exported" do
        expect(section).not_to receive(:mark_as_exported!)

        Publishing::PublishAdapter.publish_manual_and_sections(manual, republish: true)
      end

      it "unpublishes all manual's removed sections via Publishing API" do
        expect(Services.publishing_api).to receive(:unpublish).with(
          removed_section_uuid,
          anything,
        )

        Publishing::PublishAdapter.publish_manual_and_sections(manual, republish: true)
      end

      it "does not mark all manual's removed sections as exported" do
        expect(removed_section).not_to receive(:withdraw_and_mark_as_exported!)

        Publishing::PublishAdapter.publish_manual_and_sections(manual, republish: true)
      end

      context "and removed section is withdrawn" do
        let(:removed_section) { FactoryBot.create(:section, uuid: removed_section_uuid, state: "archived") }

        it "unpublishes all manual's removed sections via Publishing API" do
          expect(Services.publishing_api).to receive(:unpublish).with(
            removed_section_uuid,
            anything,
          )

          Publishing::PublishAdapter.publish_manual_and_sections(manual, republish: true)
        end
      end
    end
  end
end
