Rails.application.routes.draw do
  get '/redrock', to: 'redrock#index'
  get '/redrock/faq', to: 'redrock#faq'
  get '/redrock/rainy-day-options', to: 'redrock#rainy_day_options'

  root :to => redirect('redrock')
end
