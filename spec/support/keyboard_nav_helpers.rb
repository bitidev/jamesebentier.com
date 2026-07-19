# frozen_string_literal: true

# Shared helpers for the keyboard-nav system specs (spec/system/keyboard_nav_spec.rb,
# spec/system/keyboard_nav_normal_navigation_spec.rb). See
# docs/specs/1187-modal-vim-keyboard-navigation.md.
#
# Both helpers exist to harden these specs against a real CI-only race: on a
# loaded/cold GitHub Actions runner, keyboard_nav_controller#connect() (see
# app/javascript/controllers/keyboard_nav_controller.js) can take measurably longer
# to run than it does locally (warm asset cache, idle machine). A key dispatched
# immediately after `visit`/a Turbo navigation can therefore be sent before the
# document-level keydown listener exists to receive it -- silently swallowed, no
# error, just no effect. This reproduced 8/8 of the CI-only failures on run
# 29686067631 (dialog never opens, scroll/nav keys have zero effect) while every
# spec passed 100% locally, including under 100x CDP CPU throttling -- consistent
# with CI-only asset-serving/compile latency delaying connect(), not a genuine
# headless-Chrome product bug.
module KeyboardNavHelpers
  # Blocks (via Capybara's normal retrying wait) until keyboard_nav_controller
  # #connect() has run: it un-hides #keyboard-status-line (removes the "hidden"
  # class) in the same synchronous call that attaches the document keydown
  # listener. Deliberately NOT `visible: :all` -- the status line's text is
  # present in the server-rendered markup from first paint regardless of JS, so
  # only the default visibility filter (which respects the "hidden" class) is an
  # actual proxy for "JS has connected." Call this after every `visit`/navigation
  # and before dispatching any key.
  def wait_for_keyboard_nav_connected
    expect(page).to have_selector("#keyboard-status-line", text: "-- NORMAL --")
  end

  # Dispatches real keydown/keyup CDP events directly (Ferrum's
  # Input.dispatchKeyEvent), bypassing Capybara's find(...).send_keys. Cuprite's
  # Page#send_keys (capybara-cuprite's page.rb) performs a REAL CLICK on the
  # target node first (before_click's scrollIntoViewport + mouseEventTest) -- for
  # a full-height <body>, that click lands wherever the body's bounding-rect
  # center happens to fall (an <img>, a link, arbitrary content), which both
  # scrolls the page as a side effect (corrupting scroll-position assertions) and,
  # on any layout difference between environments (e.g. image load timing), can
  # land on a real link and navigate away before the key is ever dispatched -- a
  # false pass/fail unrelated to the keyboard-nav feature under test. A bare
  # keydown with no explicit focus target lands on document.activeElement
  # (document.body by default on a fresh page load / after a Turbo visit), exactly
  # what the feature's document-level listener expects.
  def press(*keys)
    page.driver.browser.page.keyboard.type(*keys)
  end
end

RSpec.configure do |config|
  config.include KeyboardNavHelpers, type: :system
end
