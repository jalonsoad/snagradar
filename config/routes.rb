Rails.application.routes.draw do
  # ─── Authentication ───────────────────────────────────────────────
  resource  :session
  resources :passwords, param: :token
  resource  :registration, only: [:new, :create], path: "sign_up"
  resource  :onboarding,   only: [:new, :create]

  # ─── Authenticated app ────────────────────────────────────────────
  get "dashboard", to: "dashboards#show", as: :dashboard
  get "testpage",  to: "testpages#show",  as: :testpage

  resources :defects do
    collection do
      post "classify", to: "defects/classifications#create"
    end
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

  resources :appointments,  only: %i[index update destroy]
  resources :notifications, only: %i[index update]
  resources :invitations,   only: %i[index new create destroy]
  # Tokenised accept flow — uses a separate helper name to avoid colliding
  # with the resourceful :invitation helper that destroy uses.
  get   "invite/:token", to: "invitations#show",   as: :accept_invitation
  patch "invite/:token", to: "invitations#update"
  get  "reports",            to: "reports#index", as: :reports
  get  "reports/defects.csv", to: "reports#defects_csv", as: :reports_defects_csv
  get  "search",             to: "searches#index", as: :search

  # ─── Tokenised contractor portal (no auth) ────────────────────────
  scope "/c/:token", controller: :contractor_portal, as: :contractor_portal do
    get  "",                    action: :show
    post "accept",              action: :accept,              as: :accept
    post "reject",              action: :reject,              as: :reject
    post "propose_appointment", action: :propose_appointment, as: :propose_appointment
    post "complete",            action: :complete,            as: :complete
  end

  # ─── Tokenised resident sign-off (no auth) ────────────────────────
  scope "/s/:token", controller: :sign_offs, as: :resident_signoff do
    get  "", action: :new
    post "", action: :create
  end

  # ─── Misc ─────────────────────────────────────────────────────────
  get "up" => "rails/health#show", as: :rails_health_check

  # Browser-based outgoing-mail preview in dev
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  root      "pages#home"
  get "features", to: "pages#features", as: :features
  get "pricing",  to: "pages#pricing",  as: :pricing
  get "about",    to: "pages#about",    as: :about
  get  "contact", to: "pages#contact",         as: :contact
  post "contact", to: "pages#submit_contact",  as: :submit_contact
  get "privacy",  to: "pages#privacy",  as: :privacy
  get "terms",    to: "pages#terms",    as: :terms
end
