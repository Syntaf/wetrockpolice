Rails.application.routes.draw do
  devise_for :users
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  
  resources :cash, controller: 'cash_validations', only: %i( index update destroy )
  resources :memberships, only: %i( destroy )

  scope '/:slug', 
        controller: 'watched_area',
        as: :watched_area,
        module: :area do
    resources :rainy_day_options, path: 'rainy-day-options', only: %i( index )
    get'/faq', action: :faq, as: :faq
    get '/', action: :index
  end

  root :to => redirect('redrock')
end
