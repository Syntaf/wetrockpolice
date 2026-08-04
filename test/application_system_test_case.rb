# frozen_string_literal: true

require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Headless: CI runners have no display, and a visible browser window is
  # noise locally too. selenium-manager (bundled with selenium-webdriver 4.x)
  # resolves a matching chromedriver on its own -- no webdrivers gem needed.
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end
