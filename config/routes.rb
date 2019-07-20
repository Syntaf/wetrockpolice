Rails.application.routes.draw do
  devise_for :users
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'  

  namespace :redrock, defaults: { watched_area_id: 1 } do
    get '/', to: '/redrock#index'
    get '/faq', to: '/redrock#faq'
    get '/rainy-day-options', to: '/redrock#rainy_day_options'
    get '/climbing_area', to: '/redrock#climbing_area'
  end

  # get '/redrock', to: 'redrock#index'
  # get '/redrock/faq', to: 'redrock#faq'
  # get '/redrock/rainy-day-options', to: 'redrock#rainy_day_options'
  # get '/redrock/climbing_area', to: 'redrock#climbing_area'

  # root :to => redirect('redrock')
end
