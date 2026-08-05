Rails.application.routes.draw do
  devise_for :users

  mount RailsAdmin::Engine => '/admin/manage', as: 'rails_admin'
  get '/admin', to: redirect('/admin/manage')

  # Liveness: Rails' built-in health endpoint. Process-is-up only, no
  # database involved, so a slow or down Postgres can never kill pods.
  get 'up' => 'rails/health#show', as: :rails_health_check
  # Readiness: must touch the database -- a pod that cannot reach Postgres
  # is pulled from the Service until it recovers.
  get 'ready' => 'health#ready', as: :readiness_check

  scope '/:slug', controller: 'watched_area', module: :area, as: :watched_area do
    resources :rainy_day_options, path: 'rainy-day-options', only: %i( index show )
    resources :faqs, path: 'faq', only: %i( index )

    # Server-side Synoptic proxy; keeps the API token out of shipped JS.
    get 'precipitation', controller: 'weather', action: :show, as: :precipitation

    get '/', action: :index
  end


  root :to => redirect('redrock')
end
