Rails.application.routes.draw do
  # ─── Authentication ───────────────────────────────────────────────
  resource  :session
  resources :passwords, param: :token
  resource  :registration, only: [:new, :create], path: "sign_up"
  resource  :onboarding,   only: [:new, :create]

  # ─── Authenticated app ────────────────────────────────────────────
  get "dashboard", to: "dashboards#show", as: :dashboard

  resources :defects do
    member do
      post :assign
      post :accept
      post :reject
      post :complete
      post :reopen
      post :close
    end
    resources :comments,     only: [:create]
    resources :appointments, only: [:create, :update, :destroy]
  end

  resources :sites do
    resources :plots, only: [:index, :create, :update, :destroy]
  end
  resources :trades,               except: [:show]
  resources :contractor_companies, except: [:show], path: "contractors"

  # ─── Misc ─────────────────────────────────────────────────────────
  get "up" => "rails/health#show", as: :rails_health_check

  root      "pages#home"
  get "features", to: "pages#features", as: :features
  get "pricing",  to: "pages#pricing",  as: :pricing
  get "about",    to: "pages#about",    as: :about
  get  "contact", to: "pages#contact",         as: :contact
  post "contact", to: "pages#submit_contact",  as: :submit_contact
  get "privacy",  to: "pages#privacy",  as: :privacy
  get "terms",    to: "pages#terms",    as: :terms
end
