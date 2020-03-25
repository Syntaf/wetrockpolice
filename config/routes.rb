Rails.application.routes.draw do
  devise_for :users
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  
  resources :cash, controller: 'cash_validations', only: %i( index update destroy )
  resources :memberships, only: %i( destroy )

  scope '/:slug', controller: 'watched_area', module: :area, as: :watched_area do
    resources :rainy_day_options, path: 'rainy-day-options', only: %i( index show )
    resources :faqs, path: 'faq', only: %i( index )
    
    scope '/:coalition_slug', controller: 'memberships', as: :local_climbing_org do
      get '/', action: :new
      post '/', action: :create, as: :new_membership
      post '/validate', action: :validate, as: :validate
    end

    get '/', action: :index
  end

  root :to => redirect('redrock')
end
