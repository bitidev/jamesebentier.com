# frozen_string_literal: true

# Browser-driven system specs (spec/system/**/*_spec.rb) -- Capybara + Cuprite
# (headless Chrome over the Chrome DevTools Protocol, no Selenium server/grid,
# no separate ChromeDriver binary to keep in sync).
#
# Rationale: docs/specs/1187-modal-vim-keyboard-navigation.md (Testing Strategy).
#
# `capybara/rails` wires up RSpec::Rails::SystemExampleGroup (the `type: :system`
# spec helpers -- `visit`, `page`, etc. against the Rails app under test).
require "capybara/rails"
require "capybara/rspec"
require "capybara/cuprite"

# Cuprite/Ferrum driver options, defined once and threaded through `driven_by`
# below.
#
# IMPORTANT -- why these live here and are passed via `driven_by ..., options:`
# rather than only via `Capybara.register_driver(:cuprite)`:
# `driven_by :cuprite` in a Rails/RSpec system spec goes through
# ActionDispatch::SystemTesting::Driver, which treats :cuprite as a "registerable"
# driver and CALLS `Capybara.register_driver(:cuprite)` ITSELF -- silently
# overwriting any block we registered up front. Rails' registration builds the
# driver from the hash we hand to `driven_by(..., options: ...)`; anything not in
# that hash is lost (browser_path, browser_options, process_timeout, ...), so
# without this the driver fell back to Ferrum defaults -- no --no-sandbox and
# process_timeout: 10 -- which is exactly what produced
# `Ferrum::ProcessTimeoutError: ... within 10 seconds` on CI.
CUPRITE_DRIVER_OPTIONS = {
  window_size: [1200, 800],
  # CI (GitHub Actions) launches Chrome from the browser-actions/setup-chrome
  # binary; CI exports its path as CUPRITE_CHROME_PATH (see .github/workflows/
  # ci.yml). Locally this is unset, so `browser_path: nil` falls back to Ferrum's
  # normal auto-detection of the system Chrome/Chromium.
  browser_path: ENV.fetch("CUPRITE_CHROME_PATH", nil),
  # Upper bound on how long Ferrum waits for Chrome to boot and print its
  # DevTools websocket URL. Only a ceiling -- a browser that boots fast (local
  # dev, ~1s) never pays it -- so bumped from 10 to give a cold CI Chrome
  # headroom before Ferrum::ProcessTimeoutError.
  process_timeout: 30,
  # Per-CDP-command timeout; likewise raised from 10 so a slow first paint on a
  # loaded CI runner doesn't spuriously time out. Harmless locally.
  timeout: 30,
  headless: true,
  # Raise a real Ruby exception on an uncaught in-page JS error instead of silently
  # swallowing it -- e.g. surfaces a duplicate keydown listener double-firing a
  # showModal() call (the second call throws, since a <dialog> can't be shown modally
  # twice), which is exactly the Increment 0 "no duplicate listeners across Turbo
  # navigations" regression this feature must never ship.
  js_errors: true,
  # GitHub Actions runners require Chrome to run with --no-sandbox or it fails to
  # start. Harmless locally too, so applied unconditionally. `disable-dev-shm-usage`
  # avoids Chrome crashing/hanging on the small /dev/shm partition hosted runners
  # provide.
  browser_options: { "no-sandbox" => nil, "disable-gpu" => nil, "disable-dev-shm-usage" => nil }
}.freeze

# Registered for completeness / any non-`driven_by` use of the :cuprite driver.
# Note: Rails' system-test harness re-registers :cuprite when `driven_by :cuprite`
# runs (see the comment on CUPRITE_DRIVER_OPTIONS), so the options that actually
# take effect for system specs are the ones passed through `driven_by` below.
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, CUPRITE_DRIVER_OPTIONS.dup)
end

# Plain (non-JS) system specs stay on the fast, no-browser-required rack_test
# driver; specs that need to exercise real keydown events / JS opt in with
# `js: true` and get Cuprite's real headless Chrome.
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :cuprite
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, :js, type: :system) do
    # Pass options: so ActionDispatch::SystemTesting::Driver's re-registration of
    # :cuprite actually receives our browser_path / --no-sandbox / process_timeout,
    # instead of silently falling back to Ferrum defaults. screen_size: is passed
    # too because Rails' register_cuprite does `options.merge(window_size:
    # @screen_size)` -- without it our window_size would be clobbered to nil.
    driven_by :cuprite, screen_size: [1200, 800], options: CUPRITE_DRIVER_OPTIONS.dup
  end
end
