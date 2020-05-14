require "spec_helper"
require "gds_api/test_helpers/link_checker_api"

describe LinkCheckReportsController, type: :controller do
  include GdsApi::TestHelpers::LinkCheckerApi

  let(:user) { FactoryBot.create(:user) }
  let(:manual) { FactoryBot.build(:manual, id: 538, body: "[link](http://[www.example.com)") }
  let(:section) { FactoryBot.create(:section_edition, id: 53_880, body: "[link](http://[www.example.com/section)") }

  before do
    login_as_stub_user
    allow(Manual).to receive(:find).and_return(manual)
    allow(Section).to receive(:find).and_return(section)
    allow(section).to receive(:manual).and_return(manual)
    # This is needed as the real section will be_a Section
    allow(section).to receive(:is_a?).and_return(Section)
  end

  describe "#create" do
    before do
      stub_link_checker_api
    end

    context "when there are no links" do
      let(:manual) { FactoryBot.build(:manual, id: 538, body: "hello") }

      it "returns 422 for AJAX requests" do
        post :create, xhr: true, params: { link_reportable: { manual_id: manual.id } }
        expect(response.status).to eq(422)
      end

      it "redirects POST page" do
        post :create, params: { link_reportable: { manual_id: manual.id } }

        expect(response).to redirect_to(root_path)
      end
    end

    context "manual" do
      it "POST returns a redirects to the manual show page" do
        post :create, params: { link_reportable: { manual_id: manual.id } }

        expected_path = manual_path(manual.to_param)
        expect(response).to redirect_to(expected_path)
        expect(LinkCheckReport.count).to eq(1)
      end

      it "AJAX POST renders the create template and creates a link check report" do
        post :create, xhr: true, params: { link_reportable: { manual_id: manual.id } }

        expect(response).to render_template("admin/link_check_reports/create")
        expect(LinkCheckReport.count).to eq(1)
      end
    end

    context "section" do
      it "POST returns redirects to the section show page" do
        post :create, params: { link_reportable: { manual_id: manual.id, section_id: section.id } }

        expected_path = manual_section_path(manual.to_param, section.to_param)
        expect(response).to redirect_to(expected_path)
        expect(LinkCheckReport.count).to eq(1)
      end

      it "AJAX POST renders the create template and creates a link check report" do
        post :create, xhr: true, params: { link_reportable: { manual_id: manual.id, section_id: section.id } }

        expect(response).to render_template("admin/link_check_reports/create")
        expect(LinkCheckReport.count).to eq(1)
      end
    end
  end

  describe "#show" do
    context "manual" do
      let(:link_check_report) do
        FactoryBot.create(
          :link_check_report,
          :with_broken_links,
          manual_id: manual.id,
          batch_id: 1,
        )
      end

      it "GET redirects back to the manual page" do
        get :show, params: { id: link_check_report.id }

        expected_path = manual_path(manual.to_param)
        expect(response).to redirect_to(expected_path)
      end

      it "AJAX GET assigns the LinkCheckReport and renders the show template" do
        get :show, xhr: true, params: { id: link_check_report.id }

        expect(response).to render_template("admin/link_check_reports/show")
        expect(assigns(:report)).to eq(link_check_report)
        expect(assigns(:reportable)).to eq(manual_id: manual.id.to_s)
      end
    end

    context "section" do
      let(:link_check_report) do
        FactoryBot.create(
          :link_check_report,
          :with_broken_links,
          manual_id: manual.id,
          section_id: section.id,
          batch_id: 1,
        )
      end

      it "GET redirects back to the section page" do
        get :show, params: { id: link_check_report.id }

        expected_path = manual_section_path(manual.to_param, section.to_param)
        expect(response).to redirect_to(expected_path)
      end

      it "AJAX GET assigns the LinkCheckReport and renders the show template" do
        get :show, xhr: true, params: { id: link_check_report.id }

        expect(response).to render_template("admin/link_check_reports/show")
        expect(assigns(:report)).to eq(link_check_report)
        expect(assigns(:reportable)).to eq(manual_id: manual.id.to_s, section_id: section.id.to_s)
      end
    end
  end

private

  def stub_link_checker_api
    body = link_checker_api_batch_report_hash(
      id: 5,
      links: [{ uri: "http://www.example.com" }],
    )

    stub_request(:post, %r{\A#{Plek.find('link-checker-api')}\/batch})
      .to_return(
        body: body.to_json,
        status: 202,
        headers: { "Content-Type": "application/json" },
      )
  end
end
