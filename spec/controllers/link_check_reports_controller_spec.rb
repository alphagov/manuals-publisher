require "spec_helper"
require "services"

describe LinkCheckReportsController, type: :controller do
  describe "#create" do
    let(:user) { create(:user) }
    let(:manual) { double(:manual, id: 1, body: "[link](http://www.example.com)") }
    let(:section) { FactoryGirl.create(:section_edition, id: 1) }

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
      login_as_stub_user
      allow(Services.link_checker_api).to receive(:create_batch).and_return(link_checker_api_response)
      allow(Manual).to receive(:find).and_return(manual)
      allow(Section).to receive(:find).and_return(section)
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
    it "shows the report" do
      get :show, params: {} 
      expect(response).to have_http_status(:success)
    end
  end
end
