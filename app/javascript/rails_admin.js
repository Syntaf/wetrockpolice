// rails_admin JS entry point, bundled by esbuild (see "build" in
// package.json) into app/assets/builds/rails_admin.js together with all of
// its dependencies (jquery, jquery-ui widgets, bootstrap, flatpickr,
// @rails/ujs, @hotwired/turbo-rails 7.x — rails_admin's own pinned major —
// from the rails_admin npm package's dependency tree). The engine importmap
// (config/importmap.rails_admin.rb) carries a single bare
// `pin "rails_admin"` that Propshaft resolves to the built bundle, so no
// admin JS is fetched from a CDN at runtime.
import "rails_admin/src/rails_admin/base";
