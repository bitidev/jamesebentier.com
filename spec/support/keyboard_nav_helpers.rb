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
  # One-time-per-page ceiling for the Stimulus-boot wait below. This is NOT a
  # per-assertion timeout -- it's how long we allow a *cold CI runner* to download,
  # parse, and execute the JS bundle and run keyboard_nav_controller#connect() for
  # the first time. CI run 29686774944 timed out at Capybara's 5s
  # default_max_wait_time (spec/support/capybara.rb) with the status line present
  # but its text still "" -- i.e. connect() simply hadn't run yet within 5s of a
  # cold boot (the prior run showed connect landing right at ~5s, no margin).
  # A generous ceiling is correct and harmless: have_selector returns the instant
  # the text appears (warm local boot pays ~none of it), and it only ever affects
  # the connect gate -- every real behavior assertion (scroll position, path,
  # dialog open/closed) keeps Capybara's default wait.
  KEYBOARD_NAV_CONNECT_TIMEOUT = 30

  # Blocks until keyboard_nav_controller#connect() has run. connect() un-hides
  # #keyboard-status-line (removes the "hidden" class) and modeValueChanged()
  # writes its "-- NORMAL --" text -- both happen synchronously with attaching the
  # document keydown listener, so the visible, populated status line is a true
  # proxy for "the listener now exists to receive keys."
  #
  # Two-stage on purpose (belt-and-suspenders diagnostic): first confirm the
  # element is in the DOM at all (fast -- it's server-rendered, so a failure here
  # means the markup/layout changed, not a JS problem), THEN wait up to
  # KEYBOARD_NAV_CONNECT_TIMEOUT for the text to be populated by JS. If CI ever
  # fails the SECOND wait, the element is present but connect() never ran -- a
  # genuine "JS isn't executing" problem (bundle not loaded / controller not
  # registered), not the timing issue this widened wait addresses. Deliberately
  # NOT `visible: :all` -- the text is in the server-rendered markup regardless of
  # JS, so only the default visibility filter (which respects the "hidden" class)
  # actually proves connect() ran. Call after every visit/navigation, before any
  # key.
  def wait_for_keyboard_nav_connected
    expect(page).to have_selector("#keyboard-status-line", visible: :all)
    expect(page).to have_selector(
      "#keyboard-status-line", text: "-- NORMAL --", wait: KEYBOARD_NAV_CONNECT_TIMEOUT
    )
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
