require "spec_helper"

RSpec.describe "Checking broken links", type: :feature do
  before do
    login_as(:gds_editor)
  end

  context "on manuals" do
    let(:manual) { create_manual_without_ui({ title: "A manual", summary: "A manual summary", body: "[link](http://www.example.com)" }) }

    context "when no link check report exists" do
      it "should display a link check button if there are links in the manual" do
        visit "/manuals/#{manual.id}"
        expect(page).to have_content("Check this document for broken links")
      end

      it "should display a link check in progress if the button has been clicked" do
        FactoryBot.create(:link_check_report, manual_id: manual.id)
        visit "/manuals/#{manual.id}"
        expect(page).to have_content("Broken link report in progress.")
      end
    end

    context "when a link check with no broken links exists" do
      it "should display that there are no broken links" do
        FactoryBot.create(:link_check_report, :completed, manual_id: manual.id)
        visit "/manuals/#{manual.id}"
        expect(page).to have_content("This document contains no broken links.")
      end
    end

    context "when a link check with broken links exists" do
      it "should display that there are broken links" do
        FactoryBot.create(:link_check_report, :completed, :with_broken_links, manual_id: manual.id)
        visit "/manuals/#{manual.id}"
        expect(page).to have_content("See more details about this link")
      end
    end
  end

  context "on sections" do
    let(:manual) { create_manual_without_ui({ title: "A manual", summary: "A manual summary", body: "[link](http://www.example.com)" }) }
    let(:section) { create_section_without_ui(manual, { title: "A section", summary: "Section 1 summary", body: "[link](http://www.example.com)" }) }

    context "when no link check report exists" do
      it "should display a link check button if there are links in the manual" do
        visit "/manuals/#{manual.id}/sections/#{section.uuid}"
        expect(page).to have_content("Check this document for broken links")
      end

      it "should display a link check in progress if the button has been clicked" do
        FactoryBot.create(:link_check_report, manual_id: manual.id, section_id: section.uuid)
        visit "/manuals/#{manual.id}/sections/#{section.uuid}"
        expect(page).to have_content("Broken link report in progress.")
      end
    end

    context "when a link check with no broken links exists" do
      it "should display that there are no broken links" do
        FactoryBot.create(:link_check_report, :completed, manual_id: manual.id, section_id: section.uuid)
        visit "/manuals/#{manual.id}/sections/#{section.uuid}"
        expect(page).to have_content("This document contains no broken links.")
      end
    end

    context "when a link check with broken links exists" do
      it "should display that there are broken links" do
        FactoryBot.create(:link_check_report, :completed, :with_broken_links, manual_id: manual.id, section_id: section.uuid)
        visit "/manuals/#{manual.id}/sections/#{section.uuid}"
        expect(page).to have_content("See more details about this link")
      end
    end
  end
end
