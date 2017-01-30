require "manuals_publisher"

ManualsPublisher::Application.routes.draw do
  mount JasmineRails::Engine => "/specs" if defined?(JasmineRails::Engine)
  mount GovukAdminTemplate::Engine, at: "/style-guide"
  if Rails.env.development?
    require "sidekiq/web"
    mount Sidekiq::Web => "/sidekiq"
  end

  resources :manuals, except: :destroy do
    resources :documents, path: "sections", controller: "ManualDocuments" do
      resources :attachments, controller: :manual_document_attachments, only: [:new, :create, :edit, :update]

      # This is for persisted manual documents
      post :preview, on: :member

      get :reorder, on: :collection
      post :update_order, on: :collection

      # This is the UI page for confirming withdrawal
      get :withdraw, on: :member
    end

    post :publish, on: :member

    # This is for persisted manuals
    post :preview, on: :member

    get :original_publication_date, on: :member, action: :edit_original_publication_date
    put :original_publication_date, on: :member, action: :update_original_publication_date
  end

  # This is for new manualss
  post "manuals/preview" => "Manuals#preview", as: "preview_new_manual"
  # This is for new manual documents
  post "manuals/:manual_id/sections/preview" => "ManualDocuments#preview", as: "preview_new_manual_document"

  root to: redirect("/manuals")

  get "/healthcheck", to: proc { [200, {}, ["OK"]] }
end
