require "spec_helper"

describe ManualsController, type: :controller do
  describe "#publish" do
    context "when the user lacks permission to publish" do
      let(:manual_id) { "manual-1" }
      let(:service) { spy(Manual::PublishService) }
      before do
        login_as_stub_user
        allow_any_instance_of(PermissionChecker).to receive(:can_publish?).and_return(false)
        allow(Manual::PublishService).to receive(:new).and_return(service)
        post :publish, params: { id: manual_id }
      end

      after do
        GdsApi::GovukHeaders.clear_headers
      end

      it "redirects to the manual's show page" do
        expect(response).to redirect_to manual_path(id: manual_id)
      end

      it "sets a flash message" do
        expect(flash[:error]).to include("You don't have permission to")
      end

      it "does not publish the manual" do
        expect(service).not_to have_received(:call)
      end

      it "sets the authenticated user header" do
        expect(GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user]).to match(/uid-\d+/)
      end
    end
  end
end
