Rails.application.routes.draw do
  devise_for :users

  mount RailsAdmin::Engine => '/admin/manage', as: 'rails_admin'
  get '/admin', to: redirect('/admin/manage')

  get '/health_check', to: proc { [200, {}, ['success']] }

  scope '/:slug', controller: 'watched_area', module: :area, as: :watched_area do
    resources :rainy_day_options, path: 'rainy-day-options', only: %i( index show )
    resources :faqs, path: 'faq', only: %i( index )

    get '/', action: :index
  end


  root :to => redirect('redrock')
end
