Rails.application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users

  get '/redrock', to: 'redrock#index'
  get '/redrock/faq', to: 'redrock#faq'
  get '/redrock/rainy-day-options', to: 'redrock#rainy_day_options'

  get '/admin', to: 'admin#index'

  root :to => redirect('redrock')
end
