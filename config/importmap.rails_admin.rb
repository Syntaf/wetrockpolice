# rails_admin engine importmap (asset_source :importmap). Drawn by
# RailsAdmin::Engine's "precompile hook" initializer into
# RailsAdmin::Engine.importmap — independent of the app's own JS.
#
# Generated the way `rails g rails_admin:install --asset=importmap` does it
# (RailsAdmin::ImportmapFormatter querying api.jspm.io), except the jspm
# response is unwrapped from its `{imports: {...}}` envelope because the
# formatter was written for importmap-rails 1.x and crashes on 2.x.
# NOTE: admin JS modules load from the ga.jspm.io CDN at runtime; only the
# "rails_admin" entry pin below resolves locally (app/javascript/rails_admin.js,
# served by Propshaft). Regenerate when bumping the rails_admin gem.
pin "rails_admin", preload: true
pin "rails_admin/src/rails_admin/base", to: "https://ga.jspm.io/npm:rails_admin@3.3.0/src/rails_admin/base.js"
pin "@hotwired/turbo", to: "https://ga.jspm.io/npm:@hotwired/turbo@7.3.0/dist/turbo.es2017-esm.js"
pin "@hotwired/turbo-rails", to: "https://ga.jspm.io/npm:@hotwired/turbo-rails@7.3.0/app/javascript/turbo/index.js"
pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.8/dist/esm/popper.js"
pin "@rails/actioncable/src", to: "https://ga.jspm.io/npm:@rails/actioncable@7.2.302/src/index.js"
pin "@rails/ujs", to: "https://ga.jspm.io/npm:@rails/ujs@6.1.710/lib/assets/compiled/rails-ujs.js"
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.3.8/dist/js/bootstrap.esm.js"
pin "flatpickr", to: "https://ga.jspm.io/npm:flatpickr@4.6.13/dist/esm/index.js"
pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js"
pin "jquery-ui/", to: "https://ga.jspm.io/npm:jquery-ui@1.13.3/"
