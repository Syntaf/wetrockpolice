# frozen_string_literal: true

require 'test_helper'

# Smoke test for the rails_admin engine mount. rails_admin is the whole admin
# UI and is the highest-risk dependency in the upgrade path, so "the dashboard
# renders for a super admin" is worth a test on every hop.
class RailsAdminAccessTest < ActionDispatch::IntegrationTest
  test 'super admin gets the dashboard' do
    sign_in users(:super_admin)

    get rails_admin_path

    assert_response :success
  end

  # rails_admin 3.3 runs with `asset_source :importmap`: its stylesheet is a
  # sass build served by Propshaft from app/assets/builds, and its JS is the
  # esbuild bundle app/assets/builds/rails_admin.js, resolved by the single
  # "rails_admin" pin in the engine importmap (config/importmap.rails_admin.rb).
  # If any of that wiring breaks, the dashboard renders but ships without
  # assets — so assert the references AND that each asset actually resolves,
  # and that nothing is fetched from a CDN at runtime.
  test 'dashboard assets are served via importmap + Propshaft, not Webpacker or a CDN' do
    sign_in users(:super_admin)

    get rails_admin_path
    assert_response :success

    assert_no_match %r{/packs/}, response.body,
                    'admin must no longer reference Webpacker pack assets'

    # Propshaft-digested stylesheet built from app/assets/stylesheets/rails_admin.scss
    css_paths = response.body.scan(%r{href="(/assets/rails_admin-[a-f0-9]+\.css)"}).flatten
    assert_equal 1, css_paths.size, 'expected exactly one Propshaft-served rails_admin.css link'

    # The engine importmap is inlined; every pin must resolve to a local
    # Propshaft asset — admin JS (jquery, ujs, turbo, flatpickr, ...) is
    # bundled into rails_admin.js by esbuild, not loaded from ga.jspm.io.
    importmap_json = response.body[%r{<script type="importmap"[^>]*>(.*?)</script>}m, 1]
    assert importmap_json, 'expected an inline <script type="importmap"> in the dashboard head'
    imports = JSON.parse(importmap_json).fetch('imports')
    imports.each do |name, path|
      assert_match %r{\A/assets/}, path,
                   "importmap pin #{name} must be served locally, got #{path}"
    end
    entry_path = imports.fetch('rails_admin')
    assert_match %r{\A/assets/rails_admin-[a-f0-9]+\.js\z}, entry_path

    (css_paths + imports.values).each do |asset_path|
      get asset_path
      assert_response :success, "expected #{asset_path} to be served, got #{response.status}"
    end
  end

  test 'anonymous visitors are sent to the sign-in page' do
    get rails_admin_path

    assert_redirected_to new_user_session_path
  end

  test '/admin redirects to the engine mount point' do
    get '/admin'

    assert_response :moved_permanently
    assert_redirected_to '/admin/manage'
  end

  test 'a signed-in non-admin is denied by cancancan' do
    sign_in users(:plain_user)

    assert_raises(CanCan::AccessDenied) { get rails_admin_path }
  end

  # Direct member URLs bypass the accessible_by-scoped index screens, so they
  # are the exposure surface for the formerly-unscoped instance checks (the
  # relation + `&:present?` pattern Ability used through Phase 4b). A scoped
  # admin must reach member actions only inside their `manages` grant.
  test 'scoped admin can edit a watched area they manage' do
    sign_in users(:area_admin)

    get "/admin/manage/watched_area/#{watched_areas(:redrock).id}/edit"

    assert_response :success
  end

  # A request that raises drops the integration session's signed-in state, so
  # each denied request re-signs-in first; otherwise the follow-up request
  # would 302 to the sign-in page without ever reaching the authorization
  # check, and the assert_raises would fail for the wrong reason.
  test 'scoped admin is denied member URLs for a watched area outside manages' do
    castlerock = watched_areas(:castlerock)

    sign_in users(:area_admin)
    assert_raises(CanCan::AccessDenied) do
      get "/admin/manage/watched_area/#{castlerock.id}/edit"
    end

    sign_in users(:area_admin)
    assert_raises(CanCan::AccessDenied) do
      put "/admin/manage/watched_area/#{castlerock.id}/edit",
          params: { watched_area: { name: 'hijacked' } }
    end

    sign_in users(:area_admin)
    assert_raises(CanCan::AccessDenied) do
      delete "/admin/manage/watched_area/#{castlerock.id}/delete"
    end

    assert_equal 'Castle Rock', castlerock.reload.name
  end
end
