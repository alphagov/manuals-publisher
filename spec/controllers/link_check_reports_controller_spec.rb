require "spec_helper"

describe LinkCheckReportsController, type: :controller do
  describe "#create" do
    let(:service) { double(:service, call: nil) }

    before do
      login_as_stub_user
      expect(LinkCheckReport::CreateService).to receive(:new).and_return(service)
    end

    it "calls service" do
      expect(service).to receive(:call)
      post :create, params: { link_reportable: { type: "manual", id: 1 } }
    end

    it "returns a created status" do
      post :create, params: { link_reportable: { type: "manual", id: 1 } }
      expect(response).to have_http_status(:created)
    end
  end
end
