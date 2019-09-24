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

  describe "#discard_draft" do
    let(:manual_id) { "manual-1" }
    let(:service) { double(Manual::DiscardDraftService, call: result) }
    let(:result) { double(:result, successful?: discard_success, manual_title: "My manual") }

    before do
      login_as_stub_user
      allow(Manual::DiscardDraftService).to receive(:new).and_return(service)
      delete :discard_draft, params: { id: manual_id }
    end

    context "when the manual is discarded successfully" do
      let(:discard_success) { true }

      it "sets a flash message indicating success" do
        expect(flash[:notice]).to include("Discarded draft of My manual")
      end

      it "redirects to the manuals index" do
        expect(response).to redirect_to manuals_path
      end
    end

    context "when the manual cannot be discarded" do
      let(:discard_success) { false }

      it "sets a flash message indicating failure" do
        expect(flash[:notice]).to include("Unable to discard draft of My manual")
      end

      it "redirects to the show page for the manual" do
        expect(response).to redirect_to manual_path(manual_id)
      end
    end
  end
end
