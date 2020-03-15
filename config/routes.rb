Rails.application.routes.draw do
  devise_for :users
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  
  resources :cash, controller: 'cash_validations', only: %i( index update destroy )
  resources :memberships, only: %i( destroy )

  scope '/:slug', controller: 'watched_area', as: :watched_area do
    get '/', action: :index
    get '/faq', action: :faq, as: :faq
    get '/rainy_day_options', action: :rainy_day_options, as: :rainy_day_options
  end

  root :to => redirect('redrock')
end
