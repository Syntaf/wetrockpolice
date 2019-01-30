Rails.application.routes.draw do
  get '/redrock', to: 'redrock#index'

  root :to => redirect('redrock')
end
