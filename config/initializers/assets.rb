# frozen_string_literal: true

# Propshaft load paths beyond the defaults.
#
# rails_admin's compiled stylesheet (app/assets/builds/rails_admin.css)
# references Font Awesome webfonts as sibling URLs ($fa-font-path: "." in
# app/assets/stylesheets/rails_admin.scss), so the webfonts directory from
# the npm package must be on the asset path for Propshaft to digest and
# serve them. @fortawesome/fontawesome-free is declared explicitly in
# package.json (it is also a transitive dependency of the rails_admin npm
# package) precisely because this hardcoded path depends on it being hoisted
# to the node_modules root: Propshaft treats a missing load path as empty, so
# without the declaration a hoisting change would 404 every admin icon with
# no build-time signal. Trade-off, accepted for simplicity: the directory
# ships all FA font families even though the compiled CSS only references
# fa-solid-900 — dead weight in public/assets, never in a page payload.
Rails.application.config.assets.paths << Rails.root.join('node_modules/@fortawesome/fontawesome-free/webfonts')

# Same pattern for the app's icon font: application.scss imports
# bootstrap-icons with $bootstrap-icons-font-dir: "." so the compiled url()s
# are sibling references, resolved against this directory.
Rails.application.config.assets.paths << Rails.root.join('node_modules/bootstrap-icons/font/fonts')

# Compiler *input* must not be digested and shipped to public/assets;
# only the compiled output in app/assets/builds is served.
#
# - app/assets/stylesheets: sass sources for the two css:build bundles.
# - The engine directories are all dead code under Propshaft: rails_admin's
#   app/vendor asset trees are its legacy Sprockets sources (an entire
#   vendored Bootstrap 4 SCSS tree, jquery3.js, jquery-ui widgets, ...) —
#   the app serves the sass-built rails_admin.css and the esbuild-built
#   rails_admin.js instead; turbo-rails' turbo.min.js, actionview's
#   rails-ujs and nested_form's jquery_nested_form.js are likewise already
#   bundled (or intentionally absent) via the npm packages.
Rails.application.config.assets.excluded_paths.concat [
  Rails.root.join('app/assets/stylesheets'),
  RailsAdmin::Engine.root.join('app/assets/javascripts'),
  RailsAdmin::Engine.root.join('app/assets/stylesheets'),
  RailsAdmin::Engine.root.join('vendor/assets/fonts'),
  RailsAdmin::Engine.root.join('vendor/assets/javascripts'),
  RailsAdmin::Engine.root.join('vendor/assets/stylesheets'),
  Turbo::Engine.root.join('app/assets/javascripts'),
  NestedForm::Engine.root.join('vendor/assets/javascripts'),
  ActionView::Railtie.root.join('app/assets/javascripts')
]

# app/javascript is esbuild *input* (importmap-rails adds it to the asset
# paths); serving it raw would publish every controller, util and the dev
# weather fixture as unbundled bare-specifier ESM. It cannot go through
# excluded_paths: importmap-rails appends it as a Pathname while Propshaft's
# exclusion subtraction (Array#without against strings) only matches the
# String entries that engines contribute — and importmap-rails' initializer
# runs after this file anyway, so the entry must be removed after full
# initialization (Propshaft builds its load path lazily on first use, which
# is later still). The importmap side keeps working because its only pin,
# "rails_admin", resolves to the esbuild output in app/assets/builds.
Rails.application.config.after_initialize do
  Rails.application.config.assets.paths.delete_if do |path|
    path.to_s == Rails.root.join('app/javascript').to_s
  end
end
