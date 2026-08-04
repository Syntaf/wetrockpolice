# rails_admin engine importmap (asset_source :importmap). Drawn by
# RailsAdmin::Engine's "precompile hook" initializer into
# RailsAdmin::Engine.importmap — independent of the app's own JS.
#
# A single local pin: app/javascript/rails_admin.js is bundled by esbuild
# (package.json "build") with every dependency of rails_admin's admin UI —
# jquery, jquery-ui widgets, bootstrap, flatpickr, @rails/ujs and the
# engine-pinned @hotwired/turbo-rails 7.x — into
# app/assets/builds/rails_admin.js, which is what Propshaft resolves this
# pin to. Previously every dependency here was pinned to the ga.jspm.io CDN,
# which made admin logout (@rails/ujs DELETE links), jQuery widgets and the
# rest of the admin UI depend on a third-party host at runtime.
pin "rails_admin", preload: true
