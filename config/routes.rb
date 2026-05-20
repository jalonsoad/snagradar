Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
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
