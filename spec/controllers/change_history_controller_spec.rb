require "spec_helper"

describe ChangeHistoryController, type: :controller do
  let(:manual_record) { FactoryBot.create(:manual_record, :with_sections, state: "published") }
  let(:manual) { Manual.build_manual_for(manual_record) }
  let!(:publication_log1) { FactoryBot.create(:publication_log, slug: "#{manual.slug}/#{manual.sections.first.slug}", version_number: 1) }
  let!(:publication_log2) { FactoryBot.create(:publication_log, slug: "#{manual.slug}/#{manual.sections.first.slug}", version_number: 2) }

  before do
    login_as_stub_user
  end

  it "renders index template" do
    get :index, params: { manual_id: manual.id }

    expect(response.status).to eq 200
    expect(response).to render_template :index
    expect(assigns(:publication_logs)).to eq [publication_log2, publication_log1]
  end
end
