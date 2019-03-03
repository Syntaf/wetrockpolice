Rails.application.routes.draw do
  get '/redrock', to: 'redrock#index'
  get '/redrock/faq', to: 'redrock#faq'

  root :to => redirect('redrock')
end
