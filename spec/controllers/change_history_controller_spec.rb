describe ChangeHistoryController, type: :controller do
  let(:manual_record) { FactoryBot.create(:manual_record, :with_sections, state: "published") }
  let(:manual) { Manual.build_manual_for(manual_record) }
  let!(:publication_log1) { FactoryBot.create(:publication_log, slug: "#{manual.slug}/#{manual.sections.first.slug}", version_number: 1) }
  let!(:publication_log2) { FactoryBot.create(:publication_log, slug: "#{manual.slug}/#{manual.sections.first.slug}", version_number: 2) }
  let(:gds_editor) { FactoryBot.create(:user, permissions: %w[gds_editor]) }

  context "user has permissions" do
    before do
      login_as(gds_editor)
    end

    it "renders index template" do
      get :index, params: { manual_id: manual.id }

      expect(response.status).to eq 200
      expect(response).to render_template :index
      expect(assigns(:publication_logs)).to eq [publication_log2, publication_log1]
    end

    it "renders confirm destroy template" do
      get :confirm_destroy, params: { manual_id: manual.id, id: publication_log1.id }

      expect(response.status).to eq 200
      expect(response).to render_template :confirm_destroy
    end

    it "deletes a publication log" do
      expect(Manual::RepublishService).to receive(:call).with(user: gds_editor, manual_id: manual.id)

      delete :destroy, params: { manual_id: manual.id, id: publication_log1.id }

      expect(manual.publication_logs.count).to eq 1
      expect(flash[:success]).to include "Change note deleted."
      expect(response.status).to redirect_to manual_change_history_index_path(manual.id)
    end
  end

  context "user does not have permissions" do
    before do
      login_as_stub_user
    end

    it "redirects the user" do
      get :index, params: { manual_id: manual.id }

      expect(response.status).to eq 302
      expect(response.status).to redirect_to manual_path(manual.id)
      expect(flash[:error]).to include "You don't have permission to change history."
    end
  end
end
