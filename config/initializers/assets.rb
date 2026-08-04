# frozen_string_literal: true

# Propshaft load paths beyond the defaults.
#
# rails_admin's compiled stylesheet (app/assets/builds/rails_admin.css)
# references Font Awesome webfonts as sibling URLs ($fa-font-path: "." in
# app/assets/stylesheets/rails_admin.scss), so the webfonts directory from
# the npm package must be on the asset path for Propshaft to digest and
# serve them. This mirrors what `rails g rails_admin:install --asset=importmap`
# appends here.
Rails.application.config.assets.paths << Rails.root.join('node_modules/@fortawesome/fontawesome-free/webfonts')
