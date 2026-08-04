# frozen_string_literal: true

require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Headless: CI runners have no display, and a visible browser window is
  # noise locally too. selenium-manager (bundled with selenium-webdriver 4.x)
  # resolves a matching chromedriver on its own -- no webdrivers gem needed.
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  # Guard against a silently meaningless run. When public/assets/.manifest.json
  # exists, Propshaft switches to its static resolver and serves that
  # precompiled copy instead of the live app/assets/builds output -- so a
  # system test would exercise whatever `assets:precompile` last wrote,
  # possibly months old, and stay green through a genuinely broken bundle.
  # (Found the hard way: a sabotaged bundle still passed.) public/assets is
  # gitignored, so CI's clean checkout never trips this; it is purely a local
  # footgun, and a loud failure beats a lying green.
  setup do
    manifest = Rails.public_path.join('assets/.manifest.json')

    next unless manifest.exist?

    raise <<~MESSAGE
      #{manifest} exists, so Propshaft will serve the precompiled assets in
      public/assets instead of the current build in app/assets/builds. This
      test would then pass or fail based on stale output.

      Run `bundle exec rails assets:clobber` (then `yarn build && yarn build:css`)
      before running system tests.
    MESSAGE
  end
end
