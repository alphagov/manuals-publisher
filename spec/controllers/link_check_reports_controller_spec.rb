require "spec_helper"
require "services"

describe LinkCheckReportsController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:manual) { FactoryGirl.build(:manual, id: 538, body: "[link](http://[www.example.com)") }
  let(:section) { FactoryGirl.create(:section_edition, id: 53880, body: "[link](http://[www.example.com/section)") }

  before do
    login_as_stub_user
    allow(Manual).to receive(:find).and_return(manual)
    allow(Section).to receive(:find).and_return(section)
    allow(section).to receive(:manual).and_return(manual)
    # This is needed as the real section will be_a Section
    allow(section).to receive(:is_a?).and_return(Section)
  end

  describe "#create" do
    let(:link_checker_api_response) do
      {
        id: 1,
        completed_at: nil,
        status: "in_progress",
        links: [
          {
            uri: "http://www.example.com",
            status: "error",
            checked: Time.parse("2017-12-01"),
            warnings: ["example check warnings"],
            errors: ["example check errors"],
            problem_summary: "example problem",
            suggested_fix: "example fix"
          }
        ]
      }
    end

    before do
      allow(Services.link_checker_api).to receive(:create_batch).and_return(link_checker_api_response)
    end

    it "returns a created status" do
      post :create, params: { link_reportable: { manual_id: 1 } }
      expect(response).to have_http_status(:created)
    end

    it "returns a created status when section_id is also present" do
      post :create, params: { link_reportable: { manual_id: 1, section_id: 1 } }
      expect(response).to have_http_status(:created)
    end
  end


  describe "#show" do
    context "manual" do
      let(:link_check_report) do
        FactoryGirl.create(:link_check_report, :with_broken_links,
                                                manual_id: manual.id,
                                                batch_id: 1)
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
        expect(assigns(:reportable)).to eq(manual)
      end
    end

    context "section" do
      let(:link_check_report) do
        FactoryGirl.create(:link_check_report, :with_broken_links,
                                                manual_id: manual.id,
                                                section_id: section.id,
                                                batch_id: 1)
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
        expect(assigns(:reportable)).to eq(section)
      end
    end
  end
end
