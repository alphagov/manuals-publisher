Rails.application.routes.draw do
  if Rails.env.development?
    require "sidekiq/web"
    mount Sidekiq::Web => "/sidekiq"
  end

  resources :manuals, except: :destroy do
    resources :change_history, only: %i[index destroy] do
      get :confirm_destroy, on: :member
    end

    resources :sections do
      resources :attachments, controller: :section_attachments, only: %i[new create edit update]

      # This is for persisted sections
      post :preview, on: :member

      get :reorder, on: :collection
      post :update_order, on: :collection

      # This is the UI page for confirming withdrawal
      get :withdraw, on: :member
    end

    post :publish, on: :member

    # This is for persisted manuals
    post :preview, on: :member

    # This is for drafts that have never been published
    delete :discard_draft, on: :member

    get :confirm_publish, on: :member
    get :confirm_discard, on: :member

    get :original_publication_date, on: :member, action: :edit_original_publication_date
    put :original_publication_date, on: :member, action: :update_original_publication_date
  end

  resources :link_check_reports, only: %i[create show]

  post "/link-checker-api-callback" => "link_checker_api_callback#callback", as: "link_checker_api_callback"

  # This is for new manuals
  post "manuals/preview" => "manuals#preview", as: "preview_new_manual"
  # This is for new sections
  post "manuals/:manual_id/sections/preview" => "sections#preview", as: "preview_new_section"

  root to: redirect("/manuals")

  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::Mongoid,
    GovukHealthcheck::SidekiqRedis,
  )

  get "/whats-new" => "whats_new#index", as: :whats_new

  mount GovukPublishingComponents::Engine, at: "/component-guide"
end
