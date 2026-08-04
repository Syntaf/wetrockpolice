# WetRockPolice Stack Modernization — Design Spec

**Date:** 2026-08-03
**Status:** Awaiting owner review
**Source:** 9-agent audit of the codebase + Rails ecosystem research (Aug 2026), owner decisions recorded below.

## Goal

Move WetRockPolice from an out-of-support stack (Rails 7.1.3.2 / Ruby 3.1.7 / Webpacker 5 / Bootstrap 5.1) to the current supported stack (Rails 8.1.x / Ruby 3.4.x), refactor the frontend toolchain off retired Webpacker while **retaining server-side ERB rendering**, and delete the dormant commerce features. Every phase leaves the app deployable and revertable.

## Owner decisions (locked 2026-08-03)

1. **Commerce features (memberships, raffle, cash validations, TicketSource): delete code AND data.** Tables dropped, records not retained.
2. **Frontend bundling: esbuild** (jsbundling-rails) + cssbundling-rails (sass) + Propshaft. Chosen for performance: tree-shaken, minified single bundle (Chart.js bar-only imports instead of `chart.js/auto`, date-fns auto-shaken) — meaningfully smaller payload for mobile users at crags. Node remains in the Docker *build* stage only, never the runtime image.
3. **Postgres: keep it simple, in-cluster.** Replace the frozen `bitnamilegacy` Bitnami subchart with the official `postgres:17` image in a minimal StatefulSet + PVC. Data is reseedable (`db/seeds.rb` is maintained); take one `pg_dump` before cutover, restore users/content if convenient, otherwise reseed. Optional (non-blocking): a weekly `pg_dump` CronJob.
4. **Weather fetch: proxy server-side through Rails** (post-replatform phase). Removes the hardcoded public Synoptic token from shipped JS, adds short-TTL response caching. Charts remain client-rendered by Stimulus + Chart.js.
5. **No new error-tracking service.** Rely on log aggregation: set `RAILS_LOG_TO_STDOUT` in the deployment (today prod logs go to an ephemeral file inside the container), reduce prod `log_level` from `:debug` to `:info`.

## Target architecture

| Layer | Target |
|---|---|
| Ruby | 3.4.x (Ruby 4.0 deferred to a 2027 evaluation — ecosystem gaps remain) |
| Rails | 8.1.x (supported until Oct 2027), `load_defaults 8.1` |
| Asset pipeline | Propshaft (digest/serve) + jsbundling-rails/esbuild (JS) + cssbundling-rails/sass (Bootstrap SCSS) |
| JS runtime | Turbo 8 (turbo-rails 2.x, finally a real Gemfile dep) + Stimulus 3.2; @rails/ujs deleted |
| CSS | Bootstrap 5.3.8 (npm, single version), `--quiet-deps` for dart-sass warnings |
| Auth/admin | Devise 5.0.x, CanCanCan 3.6.x, rails_admin 3.3.0 with `asset_source :importmap` (engine-isolated; app stays on esbuild) |
| Jobs | None. Sidekiq removed (runs 0 replicas today; its only worker dies with the commerce code). Active Job adapter `:async` for stray `deliver_later`s. |
| Cache | `:memory_store` (zero `Rails.cache` call sites today; weather-proxy caching uses it) |
| Redis | Removed entirely: gems, subchart, env vars, `/admin/sidekiq` mount, cable config |
| Server | Puma 7.2+ (8.x once on-target; mind the IPv6 `::` default-bind change vs k8s probes) |
| Health | Native `/up` for liveness; small DB-touching action for readiness; `rails-healthcheck` gem removed |
| Docker | Rails-8-template multi-stage: slim base, non-root, bootsnap, `BUNDLE_DEPLOYMENT=1 BUNDLE_WITHOUT="development test"`, Node in build stage only |
| Deploy | Existing DOKS + Helm (Kamal explicitly rejected — we already have an orchestrator). Chart cleanup: `autoscaling/v2` HPA, redis/sidekiq manifests deleted, livenessProbe added |
| Mail | SendGrid SMTP unchanged; Devise mail stays synchronous-capable; `User#after_create` admin mail moves to `after_create_commit` + `deliver_later` (async adapter) |

## Non-goals

No SPA or API-first rewrite; no ViewComponents; no Tailwind (Bootstrap stays); no auth migration off Devise (Rails 8 generator lacks registration/confirmable); no Kamal; no Solid Queue/Cache/Cable (nothing to queue/cache after cleanup); no new observability vendors. The slug-based microsite architecture, Minitest + fixtures, and Chart.js all stay.

## Phase plan

Phases ship independently, in order. Each has an explicit verification gate.

### Phase 0 — Safety net & hygiene (no framework changes)

- Commit the live `values.yaml` external-dns hotfix; run `helm get values` and reconcile repo vs cluster before any Helm work.
- `.dockerignore`: add `secrets.yaml`, `.env*`, `k8s/`, `log/`, `tmp/`, `docs/`. Audit pushed Docker Hub image layers for baked secrets (`secrets.yaml`/`.env` were COPY-able until now); rotate any leaked credentials.
- One-time `pg_dump` of production (pre-migration insurance; also the restore source for Phase 5 cutover).
- Fix the live Devise/Turbo bug: `config.responder.error_status = :unprocessable_entity`, `redirect_status = :see_other` (failed sign-ins currently render 200 into Turbo Drive, which discards them).
- Add ~8 integration tests: sign-in success/failure, rails_admin dashboard as super_admin, `/admin/sidekiq` auth gate (until removed), Devise confirmation redirect, Ability `can?`/`cannot?` matrix (guards the YAML-serialized `users.manages` column through defaults bumps).
- CI: `ruby-version: .ruby-version` (currently hardcoded 3.1.4 vs pinned 3.1.7), `needs: test` on the image-push job (images currently publish even when tests fail), stop building images on `pull_request`.
- Regenerate binstubs (all carry Windows `ruby.exe` shebangs; `bin/rails` is unrunnable on macOS).
- `RAILS_LOG_TO_STDOUT=1` in deployment.yaml; prod `log_level :info`.
- Security patches within current majors: rails → 7.1.6, puma → 6.4.3+.
- Re-enable SimpleCov to baseline coverage.

**Gate:** suite green in CI on 7.1.6; failed sign-in renders the form with an error visibly in a browser.

### Phase 1 — Delete the commerce cluster (code + data)

- Delete: `Area::MembershipsController` (incl. the dangling `PayPalPayments::OrderValidator` call), memberships views/SCSS/modals, `cash_validations` view + dead routes (`/cash`, top-level `memberships#destroy`), membership/raffle mailers + templates, `JointMembershipApplication`, `ShirtOrder`, `RaffleEntry` models, `TicketSource::*` (lib + service + worker), the 7,358-line PayPal mock fixture, commented-out memberships tests, dead `SnccApplication`/`RaffleEntrySubmission` test helpers, related fixtures.
- Migration dropping `joint_membership_applications`, `shirt_orders`, `raffle_entries` tables. `local_climbing_orgs` and `watched_areas.local_climbing_org_id` **stay** (site content references the org). Route `/:slug/:coalition_slug` membership paths removed.
- Remove rails_admin registrations for deleted models and the custom `MarkDelivered` action (`lib/rails_admin/mark_delivered_action.rb`).
- Gemfile: remove `rest-client`, `seed_dump`, `hiredis`, `rails-healthcheck`. Delete ActionCable channel stubs; switch `require "rails/all"` to explicit framework requires (drop actioncable/actionmailbox/actiontext/activestorage).
- k8s: remove `PAYPAL_*`, `TICKETSOURCE_SECRET` env vars and their secret templates.
- Sidekiq removal: gem, initializer, `/admin/sidekiq` mount, `sidekiq.yaml` template, `JOB_WORKER_URL`; Active Job adapter → `:async`; `User#after_create` mail → `after_create_commit { ... deliver_later }`.
- Redis removal: `redis` gem, cache store → `:memory_store`, `REDIS_URL`, Redis subchart + vendored tarball, compose service.
- Prune `db/seeds.rb` of deleted models.

**Gate:** suite green; `rails routes` has no dead endpoints; app boots with no Redis running locally; admin CRUD works for all remaining models.

### Phase 2 — Frontend replatform (still on Rails 7.1)

Ordering rationale: Webpacker 5.4.4 on Rails ≥7.2 is untested territory, and rails_admin 3.1.2 hard-caps `rails < 8` while being welded to Webpacker (`asset_source :webpacker`). Both constraints dissolve if assets migrate first, on the current green Rails.

1. **Spike first (highest uncertainty):** rails_admin 3.3.0 (installs on 7.1; gemspec `rails >= 6.0, < 9`) with `asset_source :importmap` — the engine vendors its own assets via importmap-rails + Propshaft, isolated from the app's esbuild bundle. Verify every admin CRUD screen; delete the `_head.html.erb` layout override and the dev-mode initializer-reload hack in `ApplicationController`. Fallback if the spike fails: pin rails_admin assets via a dedicated esbuild entry from the rails_admin npm package.
2. Install propshaft + jsbundling-rails (esbuild) + cssbundling-rails (sass). Move `app/javascript/packs/application.js` → `app/javascript/application.js`; images → `app/assets/images`; SCSS → `app/assets/stylesheets`.
3. Stimulus: explicit controller registrations (4 controllers) replacing `stimulus-webpack-helpers`/`require.context`.
4. Performance work that motivated esbuild: replace `chart.js/auto` with registered bar-chart components only; keep `date-fns` named imports (auto-shaken); extract the ~39KB inline base64 hero CSS from the layout into the compiled stylesheet; single unconditional `javascript_include_tag`/`stylesheet_link_tag` pair replacing six env-branched pack-tag call sites.
5. Bootstrap 5.1.2 → 5.3.8 (single npm version; rails_admin's transitive 5.3.3 conflict disappears). Fix BS4-era leftovers: `data-toggle` → `data-bs-toggle` + tooltip init (or drop), `data-backdrop`, `custom-control-*`/`form-group` classes, missing FontAwesome icons → bootstrap-icons.
6. Hotwire: add `turbo-rails` 2.x gem properly; delete `@rails/ujs` (single call site → `form: { data: { turbo_confirm: } }` on the Devise cancel-account button); `form_for` → `form_with` (8 sites).
7. Fix broken asset references (hero `asset_path`s pointing at nonexistent public files, wrong-extension modal images), delete dead SCSS (`memberships/new.scss` gone in Phase 1; `registrations.scss`, `admin.scss`), drop PostCSS/Babel configs, `webpacker.yml`, `bin/webpack*`, webpack-dev-server compose service, `NODE_OPTIONS=--openssl-legacy-provider` from all 5 files.
8. `Procfile.dev`/`bin/dev`: web + `yarn build --watch` + `yarn build:css --watch`.

**Gate:** the 4 layout-rendering controller tests pass (they are the pipeline smoke test); manual checklist — 3 microsites × (hero image, precip tiles, chart render + daily/hourly toggle, rainy-day dropdown + Mountain Project iframe, FAQ), Devise sign-in/sign-out/registration, admin CRUD per model. `git grep openssl-legacy-provider` returns nothing.

### Phase 3 — Ruby 3.1.7 → 3.3.x (on Rails 7.1.6)

Update `.ruby-version`, `Gemfile` (`ruby file: ".ruby-version"`), both Dockerfiles, CI. Blast radius verified tiny (no kwargs-forwarding edge cases beyond `ApplicationService.call`). Capybara → `~> 3.40` here (2.18 is a 2018 relic).

**Gate:** suite green on 3.3 in CI; deployed image healthy.

### Phase 4 — Rails hops: 7.2 → 8.0 → 8.1, one deploy each

Pre-work for 7.2: delete `config/secrets.yml` + `config.read_encrypted_secrets` (mechanism removed in 7.2; prod already reads `ENV["SECRET_KEY_BASE"]`), rotate the committed dev/test `secret_key_base` values; bump meta-tags ≥ 2.21 (2.20's `actionpack < 7.2` blocks resolution); devise → 5.0.x, cancancan → 3.6.x.

Per hop: `bundle update rails` → `rails app:update` (accept the rewritten env files: `cache_classes` → `enable_reloading` etc.) → run suite with deprecations-as-errors → flip `new_framework_defaults_X_Y.rb` lines one at a time → deploy.

Hop-specific items for this codebase:
- **7.2:** no `alias_attribute` overrides or enums exist (verified) — expect a quiet hop. Watch `Ability`'s relation+block `can()` pattern under cancancan 3.6.
- **8.0:** `to_time_preserves_timezone`; keep Propshaft (already migrated); native `/up` route + DB-touching readiness action, point k8s probes at them, add livenessProbe.
- **8.1:** schema.rb column alphabetization (commit that diff separately); bracket-param parsing change; `respond_with` in `RainyDayOptionsController` → `render json:` (drops the implicit responders dependency); `render file:` 404 → `Rails.public_path.join("404.html")`; explicit `serialize :manages, coder: YAML, type: Array` with Ability tests confirming grants survive.
- Finish: Ruby 3.4.x, `load_defaults 8.1`, `force_ssl`/`assume_ssl` on (TLS at ingress), filter_parameter_logging modern list, Puma → 7.2+ (bind `0.0.0.0` explicitly or update Service/probes when trying 8.x).

**Gate per hop:** suite green, staging-style smoke of the manual checklist against a deployed replica, rails_admin exercised on every model (its 8.1 support is unreleased-territory — the one watch item).

### Phase 5 — Infra refresh + weather proxy

- Dockerfile.production → Rails 8 template shape: multi-stage (Node + asset build in builder stage), `ruby:3.4-slim` runtime, non-root user, bootsnap, `BUNDLE_DEPLOYMENT`, `bin/docker-entrypoint` with `db:prepare` option (replaces manual `migrate.sh`). Thruster optional — low value behind nginx-ingress; skip unless trivial.
- Helm: HPA → `autoscaling/v2`; drop Bitnami Postgres subchart for a minimal StatefulSet on official `postgres:17` + PVC; cutover via `pg_dump`/restore (or reseed — owner-accepted); optional weekly `pg_dump` CronJob. Remove vendored Bitnami tarballs.
- Deprecate local `make build`/`push` (CI is the image source of truth; removes the secrets-baking path permanently). Update Makefile's macOS-hardcoded shell/paths as encountered.
- **Weather proxy:** small controller endpoint (e.g. `GET /:slug/precipitation`) calling Synoptic via `Net::HTTP`, token in Rails credentials, `Rails.cache` TTL ~5–10 min per station, WebMock-tested; `watched_area_controller.js` fetches the proxy instead of Synoptic directly; delete the hardcoded token (and rotate it, since it shipped in public JS for years); keep the `MOCK_WEATHER_DATA` dev fixture path working.

**Gate:** fresh cluster-state diff clean (`helm diff`), site healthy on new image + new Postgres, charts render from proxied data, token absent from compiled JS.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| rails_admin 3.3.0 on Rails 8.1 (no release in 20 months) | Phase 2 spike; admin smoke on every hop; fallback to esbuild-bundled admin assets; worst case: pin Rails 8.0 (supported to Nov 2026) while evaluating alternatives |
| No staging environment | Each phase deployable/revertable; manual smoke checklist is the gate; `helm rollback` + previous image tag is the rollback path; logs on stdout from Phase 0 |
| Silent breakage of the weather feature (zero JS tests) | Controller tests catch pipeline breakage; explicit manual chart checklist per phase; proxy endpoint gains real request tests in Phase 5 |
| Postgres cutover data loss | Owner accepts reseed; `pg_dump` taken anyway in Phase 0 and again at cutover |
| Authz regression via `users.manages` serialization across defaults bumps | Ability test matrix in Phase 0; explicit `coder:` in Phase 4 |
| Leaked secrets in historical Docker Hub layers | Phase 0 audit + rotation; local push path deprecated in Phase 5 |

## Open items (non-blocking)

- Whether to keep the GitHub-buttons/Windy/Heap third-party scripts as-is under Turbo Drive navigation (currently head-loaded once; behavior fine, revisit if pages start morphing).
- `AdminMailer` hardcodes the owner's personal email — move to credentials/ENV during Phase 4 touch.
- Optional Puma 8.x move after 7.2 settles (IPv6 default-bind interaction with k8s probes).
