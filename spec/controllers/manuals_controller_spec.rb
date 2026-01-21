describe ManualsController, type: :controller do
  describe "#create" do
    let(:service) { instance_double(Manual::CreateService) }
    let(:manual)  { instance_double(Manual, id: 123, to_param: "123") }
    let(:form)    { instance_double("ManualForm", valid?: true, id: 123, to_param: "123") }

    let(:create_params) { { title: "New Manual", organisation_slug: "org-slug" } }

    before do
      login_as_stub_user
      allow(Manual::CreateService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(manual)
      allow(controller).to receive(:manual_form).with(manual).and_return(form)
    end

    it "redirects to the manual's show page on successful creation" do
      post :create, params: { manual: create_params }
      expect(response).to redirect_to(manual_path(form))
    end

    it "shows error messages when creation fails" do
      allow(service).to receive(:call).and_raise(
        GdsApi::HTTPUnprocessableEntity.new(
          422,
          "Unprocessable Entity",
          { "error" => { "message" => "Nope" } },
        ),
      )
      rescued_manual = instance_double(Manual)
      errors = instance_double(ActiveModel::Errors)
      allow(Manual).to receive(:new).and_return(rescued_manual)
      allow(controller).to receive(:manual_form).with(rescued_manual).and_return(form)
      allow(form).to receive(:errors).and_return(errors)

      expect(errors).to receive(:add).with(:base, /Error saving to Publishing API/i)

      post :create, params: { manual: create_params }

      expect(response).to render_template(:new)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

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

  describe "#confirm_discard" do
    let(:manual_id) { "manual-1" }
    let(:service) { double(Manual::ShowService, call: manual) }
    let(:manual) { instance_double(Manual, title: manual_title) }
    let(:manual_title) { "My manual title" }

    before do
      login_as_stub_user
      allow(Manual::ShowService).to receive(:new).and_return(service)
    end

    context "when the manual has been previously published" do
      before do
        allow(manual).to receive(:has_ever_been_published?).and_return(true)
        get :confirm_discard, params: { id: manual_id }
      end

      it "sets a flash message indicating failure" do
        expect(flash[:error]).to include("#{manual_title} cannot be discarded as it has already been published")
      end

      it "redirects to the show page for the manual" do
        expect(response).to redirect_to manual_path(manual_id)
      end
    end

    context "when the manual has not been previously published" do
      before do
        allow(manual).to receive(:has_ever_been_published?).and_return(false)
        get :confirm_discard, params: { id: manual_id }
      end

      it "renders the discard confirmation page" do
        expect(response).to render_template(:confirm_discard)
      end

      it "renders with the design system layout" do
        expect(response).to render_template("design_system")
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
        expect(flash[:success]).to include("Discarded draft of My manual")
      end

      it "redirects to the manuals index" do
        expect(response).to redirect_to manuals_path
      end
    end

    context "when the manual cannot be discarded" do
      let(:discard_success) { false }

      it "sets a flash message indicating failure" do
        expect(flash[:error]).to include("Unable to discard draft of My manual")
      end

      it "redirects to the show page for the manual" do
        expect(response).to redirect_to manual_path(manual_id)
      end
    end
  end
end
