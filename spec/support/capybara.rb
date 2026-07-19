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
    process_timeout: 10,
    timeout: 10,
    headless: true,
    # CI runners execute as root inside a container; Chrome refuses to run
    # without a real (or explicitly disabled) sandbox in that case. Harmless
    # locally too, so applied unconditionally rather than gated on ENV["CI"].
    browser_options: { "no-sandbox" => nil, "disable-gpu" => nil }
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
