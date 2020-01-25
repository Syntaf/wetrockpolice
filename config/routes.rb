Rails.application.routes.draw do
  devise_for :users
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'  

  namespace :redrock, defaults: { watched_area_id: 1 } do
    get '/', to: '/redrock#index'
    get '/faq', to: '/redrock#faq'
    get '/rainy-day-options', to: '/redrock#rainy_day_options'
    get '/climbing_area', to: '/redrock#climbing_area'
    get '/sncc', to: '/memberships#new'
  end

  namespace :castlerock, defaults: { watched_area_id: 2 } do
    get '/', to: '/castlerock#index'
    get '/faq', to: '/castlerock#faq'
    get '/rainy-day-options', to: '/castlerock#rainy_day_options'
    get '/climbing_area', to: '/castlerock#climbing_area'
  end

  resources :memberships, only: [:create, :destroy]

  root :to => redirect('redrock')
end
