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

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1200, 800],
    # CI (GitHub Actions) launches Chrome from the browser-actions/setup-chrome
    # binary rather than a system-installed Chrome; Ferrum can't auto-detect it,
    # which manifested as Ferrum::ProcessTimeoutError on every system spec (the
    # process never starts, so Ferrum waits out process_timeout and gives up).
    # CI exports the installed binary's path as CUPRITE_CHROME_PATH (see
    # .github/workflows/ci.yml). Locally this is unset, so `browser_path: nil`
    # falls back to Ferrum's normal auto-detection of the system Chrome/Chromium.
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
    # CI runners execute as root inside a container; Chrome refuses to run
    # without a real (or explicitly disabled) sandbox in that case. Harmless
    # locally too, so applied unconditionally rather than gated on ENV["CI"].
    # `disable-dev-shm-usage` avoids Chrome crashing/hanging on the small
    # /dev/shm partition GitHub-hosted runners provide.
    browser_options: { "no-sandbox" => nil, "disable-gpu" => nil, "disable-dev-shm-usage" => nil }
  )
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
    driven_by :cuprite
  end
end
