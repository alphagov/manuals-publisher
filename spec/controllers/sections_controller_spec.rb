require "spec_helper"

describe SectionsController, type: :controller do
  describe "#create" do
    let(:manual) { Manual.new }
    let(:section) { Section.new(manual: manual, uuid: "section-uuid") }
    let(:service) { double(:service, call: [manual, section]) }

    before do
      login_as_stub_user
    end

    it "symbolizes the attribute keys" do
      expected_keys = %i[title summary body change_note minor_update visually_expanded]
      submitted_attributes = {
        "title" => "title",
        "summary" => "summary",
        "body" => "body",
        "change_note" => "change_note",
        "minor_update" => true,
        "visually_expanded" => false,
      }
      expect(Section::CreateService).to receive(:new) { |args|
        expect(args[:attributes].to_hash.keys).to eq(expected_keys)
      }.and_return(service)

      post :create, params: { manual_id: "manual-id", id: "section-uuid", section: submitted_attributes }
    end

    it "removes attributes that are not permitted" do
      expect(Section::CreateService).to receive(:new) { |args|
        expect(args[:attributes].keys).not_to include(:key_that_is_not_allowed)
      }.and_return(service)

      post :create, params: { manual_id: "manual-id", id: "section-uuid", section: { key_that_is_not_allowed: "o hai" } }
    end
  end

  describe "#update" do
    let(:manual) { Manual.new }
    let(:section) { Section.new(manual: manual, uuid: "section-uuid") }
    let(:service) { double(:service, call: [manual, section]) }

    before do
      login_as_stub_user
    end

    it "symbolizes the attribute keys" do
      expect(Section::UpdateService).to receive(:new) { |args|
        expect(args[:attributes].to_hash).to have_key(:title)
      }.and_return(service)

      put :update, params: { manual_id: "manual-id", id: "section-uuid", section: { "title" => "title" } }
    end

    it "removes attributes that are not permitted" do
      expect(Section::UpdateService).to receive(:new) { |args|
        expect(args[:attributes].keys).not_to include(:key_that_is_not_allowed)
      }.and_return(service)

      post :update, params: { manual_id: "manual-id", id: "section-uuid", section: { key_that_is_not_allowed: "o hai" } }
    end
  end

  describe "#preview" do
    let(:manual) { Manual.new }
    let(:section) { Section.new(manual: manual, uuid: "section-uuid") }
    let(:service) { double(:service, call: section) }

    before do
      login_as_stub_user
    end

    it "symbolizes the attribute keys" do
      expect(Section::PreviewService).to receive(:new) { |args|
        expect(args[:attributes].to_hash).to have_key(:title)
      }.and_return(service)

      post :preview, params: { manual_id: "manual-id", id: "section-uuid", section: { "title" => "title" } }
    end

    it "removes attributes that are not permitted" do
      expect(Section::PreviewService).to receive(:new) { |args|
        expect(args[:attributes].keys).not_to include(:key_that_is_not_allowed)
      }.and_return(service)

      post :preview, params: { manual_id: "manual-id", id: "section-uuid", section: { key_that_is_not_allowed: "o hai" } }
    end
  end

  describe "#withdraw" do
    context "for a user that cannot withdraw" do
      let(:manual_id) { "manual-1" }
      let(:section_uuid) { "section-1" }
      before do
        login_as_stub_user
        allow_any_instance_of(PermissionChecker).to receive(:can_withdraw?).and_return(false)
        post :withdraw, params: { manual_id: manual_id, id: section_uuid }
      end

      after do
        GdsApi::GovukHeaders.clear_headers
      end

      it "redirects to the section's show page" do
        expect(response).to redirect_to manual_section_path(manual_id: manual_id, id: section_uuid)
      end

      it "sets a flash message" do
        expect(flash[:error]).to include("You don't have permission to")
      end

      it "sets the authenticated user header" do
        expect(GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user]).to match(/uid-\d+/)
      end
    end
  end

  describe "#destroy" do
    context "for a user that cannot withdraw" do
      let(:manual_id) { "manual-1" }
      let(:section_uuid) { "section-1" }
      let(:service) { spy(Section::RemoveService) }

      before do
        login_as_stub_user
        allow_any_instance_of(PermissionChecker).to receive(:can_withdraw?).and_return(false)
        allow(Section::RemoveService).to receive(:new).and_return(service)
        delete :destroy, params: { manual_id: manual_id, id: section_uuid }
      end

      after do
        GdsApi::GovukHeaders.clear_headers
      end

      it "redirects to the section's show page" do
        expect(response).to redirect_to manual_section_path(manual_id: manual_id, id: section_uuid)
      end

      it "sets a flash message" do
        expect(flash[:error]).to include("You don't have permission to")
      end

      it "does not withdraw the manual" do
        expect(service).not_to have_received(:call)
      end

      it "sets the authenticated user header" do
        expect(GdsApi::GovukHeaders.headers[:x_govuk_authenticated_user]).to match(/uid-\d+/)
      end
    end
  end

  context "for a user that can withdraw" do
    let(:manual) { Manual.new }
    let(:section) { Section.new(manual: manual, uuid: "section-uuid") }
    let(:service) { double(:service, call: [manual, section]) }

    before do
      login_as_stub_user
      allow_any_instance_of(PermissionChecker).to receive(:can_withdraw?).and_return(true)
    end

    it "symbolizes the attribute keys" do
      expect(Section::RemoveService).to receive(:new) { |args|
        expect(args[:attributes].to_hash).to have_key(:title)
      }.and_return(service)

      delete :destroy, params: { manual_id: "manual-id", id: "section-uuid", section: { "title" => "title" } }
    end

    it "removes attributes that are not permitted" do
      expect(Section::RemoveService).to receive(:new) { |args|
        expect(args[:attributes].keys).not_to include(:key_that_is_not_allowed)
      }.and_return(service)

      delete :destroy, params: { manual_id: "manual-id", id: "section-uuid", section: { key_that_is_not_allowed: "o hai" } }
    end
  end
end
